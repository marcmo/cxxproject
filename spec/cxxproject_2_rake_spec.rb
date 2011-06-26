$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'cxxproject'
require 'cxxproject/utils/cleanup'

RSPECDIR = File.dirname(__FILE__)
puts RSPECDIR

class SpecTaskListener
  def initialize
    @task_execution_count = 0
  end
  def before_prerequisites(name)
  end

  def after_prerequisites(name)
  end

  def before_execute(name)
    @task_execution_count += 1
  end

  def after_execute(name)
  end
  def reset_exec_count()
    @task_execution_count = 0
  end
  def get_exec_count()
    @task_execution_count
  end
end

def rebuild
  tasks = fresh_cxx.all_tasks
  execute_all_tasks(tasks)
end

#def is_older? fileA, fileB
#  File.mtime(fileA) < File.mtime(fileB)
#end
#
#def is_newer? fileA, fileB
#  File.mtime(fileA) > File.mtime(fileB)
#end

def check_rebuilding (end_product, prereq_file, should_rebuild = true)
  sleep(1)
  FileUtils.touch prereq_file
  # prereq_file should be newer
  File.mtime(prereq_file).should > File.mtime(end_product)
  rebuild
  if should_rebuild
    # prereq_file should NOT be newer
    File.mtime(prereq_file).should <= File.mtime(end_product)
  else
    # prereq_file should still be newer
    File.mtime(prereq_file).should > File.mtime(end_product)
  end
end

def execute_all_tasks(tasks)
  tasks.each do |tn|
    t = tn[:task]
    t.invoke
  end
end

def fresh_cxx
  Cxxproject.cleanup_rake
  outputdir = 'output'
  CxxProject2Rake.new(Dir.glob('**/project.rb'), outputdir, GCCChain)
end

def cleanup
  rm_r 'output' if File.directory?('output')
end

#def count_needed_tasks(tasks)
#  needed = 0
#  tasks.each do |tn|
#    t = tn[:task]
#    if t.needed?
#      needed = needed + 1
#    end
#  end
#  needed
#end

ONLY_ONE_HEADER = "#{RSPECDIR}/testdata/onlyOneHeader"
describe CxxProject2Rake do
  before(:all) do
    Rake::application.options.silent = true
  end

  it 'should provide runtask for executables' do
    cd ONLY_ONE_HEADER, :verbose => false do
      cleanup
      tasks = fresh_cxx.all_tasks
      Rake::Task['run:basic'].invoke
      cleanup
    end
  end

  it 'should rebuild only when one file was changed' do
    require 'cxxproject/ext/rake_listener'
    require 'cxxproject/ext/rake_dirty'

    listener = SpecTaskListener.new
    Rake::add_listener(listener)
    cd(ONLY_ONE_HEADER, :verbose => false) do
      # fresh build
      listener.reset_exec_count
      cleanup

      tasks = fresh_cxx.all_tasks
      CLOBBER.each { |fn| rm_r fn rescue nil }
      execute_all_tasks(tasks)
      fresh_build_steps = listener.get_exec_count

      # rebuild, nothing changed
      listener.reset_exec_count
      execute_all_tasks(tasks)
      rebuild_build_steps = listener.get_exec_count

      # rebuild, nothing changed
      listener.reset_exec_count
      execute_all_tasks(tasks)
      listener.get_exec_count.should == rebuild_build_steps

      # rebuild after header changed
      listener.reset_exec_count
      sleep(1)
      files2touch = Dir.glob('help.h')
      FileUtils.touch files2touch
      execute_all_tasks(fresh_cxx.all_tasks)
      rebuild_after_touch_steps = listener.get_exec_count
      rebuild_after_touch_steps.should > rebuild_build_steps

      # rebuild, nothing changed
      listener.reset_exec_count
      execute_all_tasks(tasks)
      listener.get_exec_count.should == rebuild_build_steps

      cleanup
    end
    Rake::remove_listener(listener)
  end

  it 'should rebuild when any source file changes' do
    cd("#{RSPECDIR}/testdata/basic", :verbose => false) do
      cleanup

      tasks = fresh_cxx.all_tasks
      CLOBBER.each { |fn| rm_r fn rescue nil }
      execute_all_tasks(tasks)

      # dependencies: exe -> libC -> libB

      headerA = 'exe12/help.h'
      sourceA = 'exe12/main.cpp'
      projectA = 'exe12/project.rb'
      headerB = 'lib1/lib1.h'
      sourceB = 'lib1/lib1.cpp'
      projectB = 'lib1/project.rb'
      headerC = 'lib2/lib2.h'
      sourceC = 'lib2/lib2.cpp'
      projectC = 'lib2/project.rb'
      exe = 'output/exes/basic.exe'
      libB = 'output/libs/lib1.a'
      libC = 'output/libs/lib2.a'

      check_rebuilding exe, headerA
      check_rebuilding exe, sourceA
      check_rebuilding exe, projectA
      check_rebuilding exe, headerB
      check_rebuilding exe, headerC
      check_rebuilding libB, sourceA, false
      check_rebuilding libB, sourceB

      check_rebuilding libB, sourceC, false
      check_rebuilding libC, sourceB

      cleanup
      Cxxproject.cleanup_rake
    end
  end

end

$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'cxxproject'
require 'rake'

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

describe CxxProject2Rake do
  def count_needed_tasks(tasks)
    needed = 0
    tasks.each do |tn|
      t = tn[:task]
      if t.needed?
        needed = needed + 1
      end
    end
    needed
  end
  def execute_all_tasks(tasks)
    tasks.each do |tn|
      t = tn[:task]
      t.invoke
    end
  end

  def fresh_cxx
    ALL_BUILDING_BLOCKS.clear
    Rake.application.clear
    outputdir = 'output'
    CxxProject2Rake.new(Dir.glob('project.rb'), outputdir, GCCChain)
  end

  it 'should rebuild only when one file was changed' do
    require 'cxxproject/extensions/rake_listener_ext'
    require 'cxxproject/extensions/rake_dirty_ext'
    listener = SpecTaskListener.new
    Rake::add_listener(listener)
    cd("#{RSPECDIR}/testdata/onlyOneHeader", :verbose => false) do
      # fresh build
      listener.reset_exec_count
      rm_r 'output' if File.directory?('output')
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
      sleep(0.1)
      files2touch = Dir.glob('help.h')
      FileUtils.touch files2touch
      execute_all_tasks(fresh_cxx.all_tasks)
      rebuild_after_touch_steps = listener.get_exec_count
      rebuild_after_touch_steps.should > rebuild_build_steps

      # rebuild, nothing changed
      listener.reset_exec_count
      execute_all_tasks(tasks)
      listener.get_exec_count.should == rebuild_build_steps

    end
  end

end


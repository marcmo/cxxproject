$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'cxxproject'
require 'rake'

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
      puts "invoking ... #{t}, #{t.prerequisites}"
      t.invoke
    end
  end

  def calculate_tasks
    ALL_BUILDING_BLOCKS.clear
    Rake.application.clear
    puts "caluclating all tasks"
    outputdir = 'output'
    CxxProject2Rake.new(Dir.glob('project.rb'), outputdir, GCCChain)
  end

  it 'should execute only one action when one file was changed' do
    require 'cxxproject/extensions/rake_listener_ext'
    require 'cxxproject/extensions/rake_dirty_ext'
    listener = SpecTaskListener.new
    Rake::add_listener(listener)
    cd('../testdata/onlyOneHeader', :verbose => false) do
      rm_r 'output'
      tasks = calculate_tasks.all_tasks

      listener.reset_exec_count
      execute_all_tasks(tasks)
      puts "==> exec count after fresh rebuild: #{listener.get_exec_count}"
      listener.reset_exec_count

      tasks = calculate_tasks.all_tasks
      listener.reset_exec_count
      execute_all_tasks(tasks)
      puts "==> exec count before touch: #{listener.get_exec_count}"
      listener.reset_exec_count
      
      puts "exe: #{File.mtime('output/basic.exe')}"
      puts "*.h: #{File.mtime('help.h')}"
      puts "touching .............."
      FileUtils.touch Dir.glob('help.h')
      sleep(3)
      tasks = calculate_tasks.all_tasks
      execute_all_tasks(tasks)
      puts "exe: #{File.mtime('output/basic.exe')}"
      puts "*.h: #{File.mtime('help.h')}"
      puts "==> exec count after touch: #{listener.get_exec_count}"
      listener.get_exec_count.should > 0
      
      
      # cxx = calculate_tasks
      # tasks = cxx.all_tasks
      # CLOBBER.each { |fn| puts "clobber: removing #{fn}";rm_r fn rescue nil }
      # outputter = Proc.new do |x|
      #   puts x
      # end
      # execute_all_tasks(tasks)
      # listener.reset_exec_count
      # listener.get_exec_count.should == 0
      # sleep(0.1)
      # files2touch = Dir.glob('help.h')
      # FileUtils.touch files2touch
      # execute_all_tasks(calculate_tasks.all_tasks)
      # execute_all_tasks(calculate_tasks.all_tasks)
      # execute_all_tasks(calculate_tasks.all_tasks)
      # listener.get_exec_count.should > 0
      # listener.reset_exec_count
      # execute_all_tasks(calculate_tasks.all_tasks)
      # execute_all_tasks(calculate_tasks.all_tasks)
      # execute_all_tasks(calculate_tasks.all_tasks)
      # listener.get_exec_count.should == 0
    end
  end

end


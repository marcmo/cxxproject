$:.unshift File.join(File.dirname(__FILE__),"..","lib")
require 'cxxproject'
require 'rake'


module Rake
	class Task

    @@task_execution_count = 0
	  execute_org = self.instance_method(:execute)

	  def self.get_exec_count()
	    @@task_execution_count
    end
	  def self.reset_exec_count()
	    @@task_execution_count = 0
    end

		define_method(:execute) do |*args|
			puts "execute of #{self}"
			@@task_execution_count += 1
      prerequisites().each do |p|
        x = application[p, scope]
        # puts "needed: #{x.inspect}" # unless !x.needed?
      end
			execute_org.bind(self).call(args)
		end
	end
end

def create_file_outputter(f)
  fileoutputter = Proc.new() do |x|
    f.write("digraph TaskGraph\n");
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
      # s = gw.buildGraph(t)
      t.invoke
    end
  end
  def check_execution_count(tasks)
    needed = count_needed_tasks(tasks)
    execute_all_tasks(tasks)
    puts "#{needed} tasks where needed"
    initial_exec_count = Rake::Task::get_exec_count()
    puts "task_execution_count was: #{Rake::Task::get_exec_count()}"
    Rake::Task::reset_exec_count()
  end

  it 'should execute only one action when one file was changed' do
    cd('../testdata/onlyOneHeader', :verbose => false) do
      compiler = GccCompiler.new('output')
      cxx = CxxProject2Rake.new(Dir.glob('**/project.rb'), compiler, './', Logger::ERROR, true)
      tasks = cxx.instantiate_tasks(Dir.glob('**/project.rb'), compiler)
      puts "tasks: #{tasks.inspect}"
      gw = GraphWriter.new()
      outputter = Proc.new do |x|
        puts x
      end
      check_execution_count(tasks)
      check_execution_count(tasks)
      tasks.each { |t| print_pres(t[:task]) }
      # sh "touch help.h"
      check_execution_count(tasks)
      tasks.each { |t| print_pres(t[:task]) }
      # puts "dependent_file_tasks: #{dependent_file_tasks(tasks)}"

      # CLEAN.each { |fn| rm_r fn rescue nil }
      # CLOBBER.each { |fn| rm_r fn rescue nil }
    end
  end

  def prerequisites_if_any(t)
    if t.respond_to?('prerequisites')
      t.prerequisites
    else
      []
    end
  end

  def task2string(t)
    if t.instance_of?(FileTask)
      t.name
    else
      File.basename(t.name)
    end
  end
  def print_pres(tt)
    dirty_count = 0
    inner = lambda do |t,level|
      s = ""
      if t.needed? && tt.instance_of?(FileTask) then
        level.times { s = s + "xxx" }
        puts "#{s} #{level}.level: #{task2string(t)}, deps:#{t.prerequisites.inspect}"
      else 
        level.times { s = s + "---" }
        # puts "#{s} #{level}.level: #{task2string(t)}"
      end
      dirty_count += 1 unless !(t.instance_of?(FileTask) && t.needed?)
      prerequisites = prerequisites_if_any(t)
      prerequisites.each do |p|
        x = t.application[p, t.scope]
        inner.call(x,level+1)
      end
    end
    inner.call(tt,0)
    dirty_count
  end
  def dependent_file_tasks(ts)
    file_tasks = []
    inner = lambda do |tasks|
      tasks.each do |tn|
        t = tn[:task]
        if t.instance_of?(FileTask)
          file_tasks << t
        end
        prerequisites_if_any(t).each do |p|
          inner.call(t.application[p, t.scope])
        end
      end
    end
    inner.call(ts,0)
    file_tasks
  end

  # it 'should find values in each config file' do
  #   cd('testdata/configuration/example_project', :verbose => false) do
  #     c = Configuration.new(Dir.getwd)
  #     c.get_value(:test1).should == 'test1value'
  #     c.get_value(:test2).should == 'test2value'
  #   end
  # end

  # it 'should deliver the most special values if values are defined on several levels' do 
  #   cd('testdata/configuration/example_project', :verbose => false) do
  #     c = Configuration.new(Dir.getwd)
  #     c.get_value(:test3).should == 'test1value'
  #   end
  # end

end

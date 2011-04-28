require 'rake'

module Rake

  #############
  # - Limit parallel tasks
  #############
  class MultiTask < Task
    private
    def invoke_prerequisites(args, invocation_chain)
      return unless @prerequisites
      
      jobqueue = @prerequisites.dup
      m = Mutex.new
    
      numThreads = jobqueue.length > 3 ? 3 : jobqueue.length  
    
      threads = [] 
      numThreads.times {
        threads << Thread.new(jobqueue) { |jq|
        	while true do
	            p = nil
        		m.synchronize() { p = jq.shift }
        		break unless p
        		application[p].invoke_with_call_chain(args, invocation_chain)
        	end
        }
      }
      threads.each { |t| t.join }
    end
  end
 
  

  #############
  # - Go on if a task fails (but to not execute the parent)
  # - showInGraph is used for GraphWriter (internal tasks are not shown)
  #############
  class Task
    attr_accessor :failure # specified if that task has failed
    attr_accessor :only_no_linking_if_failure # if an archive cannot be build, go on but omit linking
    attr_accessor :deps # used to store deps by depfile task for the apply task (no re-read of depsfile)
	attr_accessor :linkTask # set to true for all tasks which need the linker
	 
    execute_org = self.instance_method(:execute)
    initialize_org = self.instance_method(:initialize)
    timestamp_org = self.instance_method(:timestamp)

    attr_accessor :showInGraph

    define_method(:initialize) do |task_name, app|
      initialize_org.bind(self).call(task_name, app)
      @showInGraph = false
      @deps = nil
      @tstamp = nil
      @only_no_linking_if_failure = false
    end

    define_method(:execute) do |arg|
      # check if a prereq has failed
      @prerequisites.each { |n|
        prereq = application[n, @scope]
        if prereq.failure
        	if not prereq.only_no_linking_if_failure or @linkTask  
          		@failure = true
          	end
        end
      }
      break if @failure # if yes, this task cannot be run

      begin
        execute_org.bind(self).call(arg)
        @failure = false
      rescue Exception => ex1# todo: no rescue to stop on first error
          puts "Error: #{@name} not built/cleaned correctly: #{ex1.message}"
        begin
          FileUtils.rm(@name) if File.exists?(@name) # todo: error parsing?
        rescue Exception => ex2
          puts "Error: Could not delete #{@name}: #{ex2.message}"
        end
        @failure = true
      end
    end
    
    define_method(:timestamp) do
    	return Rake::EARLY if @prerequisites.length == 0
    	timestamp_org.bind(self).call()
    end
    

  end

end

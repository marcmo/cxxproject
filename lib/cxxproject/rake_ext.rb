require 'rake'

module Rake

  $queue = Queue.new
  $queue << "" << "" << ""

  #############
  # - Limit parallel tasks
  # - Go on if a task fails (but to not execute the parent)
  # - showInGraph is used for GraphWriter (internal tasks are not shown)
  #############
  class Task
    attr_accessor :failure
    attr_accessor :deps

    execute_org = self.instance_method(:execute)
    initialize_org = self.instance_method(:initialize)

    attr_accessor :showInGraph

    define_method(:initialize) do |task_name, app|
      initialize_org.bind(self).call(task_name, app)
      @showInGraph = false
      @deps = nil
    end

    define_method(:execute) do |arg|

      # check if a prereq has failed
      @prerequisites.each { |n|
        prereq = application[n, @scope]
        if prereq.failure
          @failure = true
        end
      }
      break if @failure # if yes, this task cannot be run

      $queue.pop

      begin
        execute_org.bind(self).call(arg)
        @failure = false
      rescue Exception => ex# todo: no rescue to stop on first error
        begin
          FileUtils.rm([@name]) # todo: is that the best way? gcc can return errors even if files are built...
        rescue
        end
        $logger.error("#{@name} not built/cleaned correctly")
        @failure = true
      end

      $queue << ""

    end

  end

end

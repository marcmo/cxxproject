require 'cxxproject/extensions/stdout_ext'
require 'cxxproject/utils/dot/graph_writer'

require 'rake'
require 'stringio'

module Rake

  class SyncStringIO < StringIO
    def initialize(mutex)
      super()
      @mutex = mutex
    end

    def sync_flush
      if string.length > 0
        @mutex.synchronize { STDOUT.write string; truncate(0); rewind}
      end
    end

  end

  #############
  # - Limit parallel tasks
  #############
  class MultiTask < Task

    @@max_parallel_tasks = 8

    def self.max_parallel_tasks
      @@max_parallel_tasks
    end

    def self.set_max_parallel_tasks(number)
      @@max_parallel_tasks = number
    end

    private
    def invoke_prerequisites(args, invocation_chain)
      return unless @prerequisites

      jobqueue = @prerequisites.dup
      m = Mutex.new

      numThreads = jobqueue.length > @@max_parallel_tasks ? @@max_parallel_tasks : jobqueue.length

      threads = []
      numThreads.times {
        threads << Thread.new(jobqueue) { |jq|
          while true do
            p = nil
            m.synchronize { p = jq.shift }
            break unless p

            s = SyncStringIO.new(m)
            Thread.current[:stdout] = s
            prereq = application[p]
            prereq.invoke_with_call_chain(args, invocation_chain)
            if prereq.failure
              @failure = true
            end
            s.sync_flush
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
    attr_accessor :deps # used to store deps by depfile task for the apply task (no re-read of depsfile)
    attr_accessor :showInGraph
    attr_accessor :transparent_timestamp
    attr_accessor :dismissed_prerequisites

    execute_org = self.instance_method(:execute)
    initialize_org = self.instance_method(:initialize)
    timestamp_org = self.instance_method(:timestamp)
    invoke_prerequisites_org = self.instance_method(:invoke_prerequisites)

    define_method(:initialize) do |task_name, app|
      initialize_org.bind(self).call(task_name, app)
      @showInGraph = GraphWriter::YES
      @deps = nil
      @transparent_timestamp = false
      @dismissed_prerequisites = []
      @neededStored = nil # cache result for performance
    end

    define_method(:invoke_prerequisites) do |task_args, invocation_chain|
      orgLength = 0
      while @prerequisites.length > orgLength do
        orgLength = @prerequisites.length
        @prerequisites.dup.each { |n| # dup needed when apply tasks changes that array
          begin
            prereq = application[n, @scope]
            prereq_args = task_args.new_scope(prereq.arg_names)
            prereq.invoke_with_call_chain(prereq_args, invocation_chain)
            if prereq.failure
              @failure = true
            end
          rescue
            if @name.length>2 and @name[-2..-1] == ".o" # file found in dep file does not exist anymore
              @prerequisites.delete(n)
              def self.needed?
                true
              end
            end
          end
        }
      end

    end

    define_method(:execute) do |arg|

      break if @failure # check if a prereq has failed
      break if BuildingBlock.idei and BuildingBlock.idei.get_abort

      begin
        execute_org.bind(self).call(arg)
        @failure = false
      rescue Exception => ex1 # todo: no rescue to stop on first error
        # todo: debug log, no puts here!
        puts "Error: #{@name} not built/cleaned correctly: #{ex1.message}"
        begin
          FileUtils.rm(@name) if File.exists?(@name) # todo: error parsing?
        rescue Exception => ex2
          # todo: debug log, no puts here!
          puts "Error: Could not delete #{@name}: #{ex2.message}"
        end
        @failure = true
      end

      Thread.current[:stdout].sync_flush if Thread.current[:stdout]

    end

    define_method(:timestamp) do
      if @transparent_timestamp
        ts = Rake::EARLY
        @prerequisites.each do |pre|
          prereq_timestamp = Rake.application[pre].timestamp
          ts = prereq_timestamp if prereq_timestamp > ts
        end
      else
        ts = timestamp_org.bind(self).call()
      end
      ts
    end

  end

end

require 'cxxproject/extensions/stdout_ext'
require 'cxxproject/utils/dot/graph_writer'

require 'rake'
require 'stringio'
require 'thread'

module Rake

  class Application
    attr_writer :max_parallel_tasks
    def max_parallel_tasks
      @max_parallel_tasks ||= 8
    end

    def idei
      @idei ||= IDEInterface.new
    end

    def idei=(value)
      @idei = value
    end

    def command_line_number
      @command_line_number ||= 1
      res = @command_line_number
      @command_line_number += 1
      res
    end
  end

  $exit_code = 0

  class Jobs
    def initialize(jobs, max, &block)
      nr_of_threads = [max, jobs.length].min
      @jobs = jobs
      @mutex = Mutex.new
      @threads = []
      nr_of_threads.times do
        @threads << Thread.new do
          block.call(self)
        end
      end
    end

    def get_next_or_nil
      the_next = nil
      @mutex.synchronize {
        the_next = @jobs.shift
      }
      the_next
    end
    def join
      @threads.each{|t|t.join}
    end
  end

  #############
  # - Limit parallel tasks
  #############
  class MultiTask < Task
    def invoke_prerequisites(args, invocation_chain)
      return unless @prerequisites
      @mutex = Mutex.new
      Jobs.new(@prerequisites.dup, application.max_parallel_tasks) do |jobs|
        while true do
          job = jobs.get_next_or_nil
          break unless job

          prereq = application[job]
          prereq.output_after_execute = false
          prereq.invoke_with_call_chain(args, invocation_chain)
          set_failed if prereq.failure
          output(prereq.output_string)
        end
      end.join
    end

    def output(to_output)
      return if Rake::Task.output_disabled
      return unless output_after_execute

      @mutex.synchronize do
        if to_output and to_output.length > 0
          puts to_output
        end
      end
    end
  end

  ###########
  # - Go on if a task fails (but to not execute the parent)
  # - showInGraph is used for GraphWriter (internal tasks are not shown)
  #############
  class Task
    class << self
      attr_accessor :bail_on_first_error
      attr_accessor :output_disabled
    end

    attr_accessor :failure # specified if that task has failed
    attr_accessor :deps # used to store deps by depfile task for the apply task (no re-read of depsfile)
    attr_accessor :type
    attr_accessor :transparent_timestamp
    attr_accessor :dismissed_prerequisites
    attr_accessor :progress_count
    attr_accessor :output_string
    attr_accessor :output_after_execute

    UNKNOWN     = 0x0000 #
    OBJECT      = 0x0001 #
    SOURCEMULTI = 0x0002 # x
    DEPFILE     = 0x0004 #
    LIBRARY     = 0x0008 # x
    EXECUTABLE  = 0x0010 # x
    CONFIG      = 0x0020 #
    APPLY       = 0x0040 #
    UTIL        = 0x0080 #
    BINARY      = 0x0100 # x
    MODULE      = 0x0200 # x
    MAKE        = 0x0400 # x
    RUN         = 0x0800 #
    CUSTOM      = 0x1000 # x
    COMMANDLINE = 0x2000 # x

    STANDARD    = 0x371A # x above means included in STANDARD
    attr_reader :ignore
    execute_org = self.instance_method(:execute)
    initialize_org = self.instance_method(:initialize)
    timestamp_org = self.instance_method(:timestamp)
    invoke_prerequisites_org = self.instance_method(:invoke_prerequisites)
    invoke_org = self.instance_method(:invoke)

    define_method(:initialize) do |task_name, app|
      initialize_org.bind(self).call(task_name, app)
      @type = UNKNOWN
      @deps = nil
      @transparent_timestamp = false
      @dismissed_prerequisites = []
      @neededStored = nil # cache result for performance
      progress_count = 0
      @ignore = false
      @failure = false
      @output_after_execute = true
      @dependency_set = Set.new
    end

    alias :enhance_org :enhance
    def enhance(deps=nil, &block)
      if deps
        deps.each do |d|
          if @dependency_set.add?(d)
            @prerequisites << d
          end
        end
      end
      @actions << block if block_given?
      self
    end

    define_method(:invoke) do |*args|
      $exit_code = 0
      invoke_org.bind(self).call(*args)
      if @failure or Rake.application.idei.get_abort
        $exit_code = 1
      end
    end

    define_method(:invoke_prerequisites) do |task_args, invocation_chain|
      new_invoke_prerequisites(task_args, invocation_chain)
    end

    def new_invoke_prerequisites(task_args, invocation_chain)
      orgLength = 0
      while @prerequisites.length > orgLength do
        orgLength = @prerequisites.length

        @prerequisites.dup.each do |n| # dup needed when apply tasks changes that array
          break if Rake.application.idei.get_abort
          begin
            prereq = application[n, @scope]
            prereq_args = task_args.new_scope(prereq.arg_names)
            prereq.invoke_with_call_chain(prereq_args, invocation_chain)
            set_failed if prereq.failure
          rescue Exception => e
            optional_prereq_or_fail(n)
          end
        end
      end
    end

    def optional_prereq_or_fail(n)
      begin
        if Rake::Task[n].ignore
          @prerequisites.delete(n)
          def self.needed?
            true
          end
          return
        end
      rescue => e
        puts "Error #{name}: #{e.message}"
      end
      set_failed
    end

    def set_failed()
      @failure = true
      if Rake::Task.bail_on_first_error
        Rake.application.idei.set_abort(true)
      end
    end

    define_method(:execute) do |arg|
      break if @failure # check if a prereq has failed
      break if Rake.application.idei.get_abort

      new_execute(execute_org, arg)

      Thread.current[:stdout].sync_flush if Thread.current[:stdout]
    end

    def new_execute(execute_org, arg)
      s = StringIO.new
      Thread.current[:stdout] = s

      begin
        execute_org.bind(self).call(arg)
      rescue Exception => ex1
        handle_error(ex1)
      end

      self.output_string = s.string
      Thread.current[:stdout] = nil

      output(self.output_string)
    end

    def handle_error(ex1)
      # todo: debug log, no puts here!
      if not Rake.application.idei.get_abort()
        puts "Error for task: #{@name} #{ex1.message}"
      end
      begin
        FileUtils.rm(@name) if File.exists?(@name) # todo: error parsing?
      rescue Exception => ex2
        # todo: debug log, no puts here!
        puts "Error: Could not delete #{@name}: #{ex2.message}"
      end
      set_failed
    end

    def output(to_output)
      return if Rake::Task.output_disabled
      return unless output_after_execute

      if to_output and to_output.length > 0
        puts to_output
      end
    end

    reenable_org = self.instance_method(:reenable)
    define_method(:reenable) do
      reenable_org.bind(self).call
      @failure = false
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

    def ignore_missing_file
      @ignore = true
    end

    def visit(&block)
      if block.call(self)
        prerequisite_tasks.each do |t|
          t.visit(&block)
        end
      end
    end

  end


  at_exit do
    exit($exit_code)
  end

end

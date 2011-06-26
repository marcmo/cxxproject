module Cxxproject
  module Utils
    class ProgressHelper

      attr_reader :todo

      attr_reader :needed_tasks

      def initialize
        @todo = 0.0
        @needed_tasks = {}
      end

      def count_with_filter(name)
        tasks = find_tasks_for_toplevel_task(name)
        tasks.each do |t|
          count(t)
        end
        if @todo < 1
          @todo = 1
        end
      end

      def find_tasks_for_toplevel_task(name)
        regex = create_regex_for_name(name)
        return filter_all_tasks(regex)
      end

      def create_regex_for_name(name)
        res = Regexp.new(name)
        res = create_regex_for_filter(name, res)
        return res
      end

      def is_filter(name)
        return name.index('filter')
      end

      def create_regex_for_filter(name, res)
        return res unless is_filter(name)

        name = name.gsub('filter', '')
        if name.index('[') == nil
          name = name + '.*'
        else
          name = name.gsub('[', '')
          name = name.gsub(']', '')
        end
        return Regexp.new(name)
      end

      def filter_all_tasks(regex)
        return Rake::Task::tasks.find_all do |t|
          task_name = t.name
          res = ((task_name.index('filter') == nil) && regex.match(task_name)!=nil)
        end
      end

      def count(task)
        task.visit() do |t|
          count_needed_tasks(t)
          true
        end
      end

      def count_needed_tasks(t)
        c = t.progress_count
        if c && c > 0
          if t.needed? && @needed_tasks[t.name] == nil
            @needed_tasks[t.name] = true
            @todo += c
          end
        end
      end
    end
  end
end

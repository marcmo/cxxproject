module Cxxproject
  module Utils
    define_progress = lambda do
      require 'rake'
      require 'cxxproject/ext/rake'

      require 'progressbar'
      require 'cxxproject/ext/progressbar'
      require 'colored'
      require 'cxxproject/utils/progress_helper'

      class ProgressListener
        def initialize
          @progress_helper = ProgressHelper.new
          Rake::application.top_level_tasks.each do |name|
            @progress_helper.count_with_filter(name)
          end
          @progress = ProgressBar.new('all tasks', @progress_helper.todo)
          @progress.title_width = 30
          @progress.unblock
        end

        def after_execute(name)
          needed_tasks = @progress_helper.needed_tasks
          if needed_tasks[name]
            task = Rake::Task[name]
            @progress.title = task.name
            @progress.inc(task.progress_count)
            if (@progress.total == @progress.current)
              puts
            end
          end
        end
      end

      require 'benchmark'
      class BenchmarkedProgressListener < ProgressListener
        def initialize
          Benchmark.bm do |x|
            x.report('ProgressListener.initialize') do
              super
            end
          end
        end
      end

      desc 'show a progressbar for the build (use with -s for best results)'
      task :progress do
        require 'cxxproject/ext/rake_listener'
        Rake::add_listener(ProgressListener.new)
      end

      task :benchmark_progress do
        require 'cxxproject/ext/rake_listener'
        Rake::add_listener(BenchmarkedProgressListener.new)
      end
    end

    could_not_define_progress = lambda {
      task :progress do
        puts 'could not define progress'
      end
    }
    optional_package(define_progress, could_not_define_progress)
  end
end

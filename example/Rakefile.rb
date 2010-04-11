desc 'clean all examples'
task :clean_all do
  run_rakefiles{ sh "rake clobber" }
end

desc 'build all examples'
task :all_examples do
  run_rakefiles { sh "rake" }
end

desc "run all exes - task"
task :runexes do
  run_rakefiles do
    if Rake::Task.task_defined?(:run)
      Rake::Task.invoke(:run)
    else
      p "no run task exists in #{`pwd`}, only those tasks exist:"
      p Rake::Task.tasks.collect {|t| t.name}
    end
  end
end
task :default => :all_examples

def run_rakefiles()
  Dir.glob('**/Rakefile.rb').each do |p|
    dir = File.dirname(p)
    if (dir != ".")
      FileUtils.cd(dir,:verbose => false)  do
        yield
      end
    end
  end
end

task :clean => :clean_all

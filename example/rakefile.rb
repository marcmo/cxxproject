
desc 'clean all examples'
task :clean_all do
  run_rakefiles("rake clean")
end

desc 'build all examples'
task :all_examples do
  run_rakefiles("rake")
end

task :default => :all_examples

def run_rakefiles(c)
  Dir.glob('**/Rakefile.rb').each do |p|
    dir = File.dirname(p)
    cd dir do
      sh "#{c}"
    end
  end
end

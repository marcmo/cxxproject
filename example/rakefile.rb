
desc 'build all examples'
task :all_examples do
  Dir.glob('**/Rakefile.rb').each do |p|
    dir = File.dirname(p)
    cd dir do
      puts "running rake in #{dir}"
      sh "rake"
    end
  end
end

task :default => :all_examples

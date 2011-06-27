require 'rake/clean'

require './rake_helper/spec.rb'

desc "Default Task"
task :default => [:install]

require 'rubygems/package_task'
spec = Gem::Specification.load('cxx.gemspec')
Gem::PackageTask.new(spec){|pkg|}

begin
  require 'roodi'
  require 'roodi_task'
  class RoodiTask
    def define
      # copied from roodi_task.rb
      desc "Check for design issues in: #{patterns.join(', ')}"
      task name do
        runner = Roodi::Core::Runner.new
        runner.config = config if config
        patterns.each do |pattern|
          Dir.glob(pattern).each { |file| runner.check_file(file) }
        end
        runner.errors.each {|error| puts error}
        # raise "Found #{runner.errors.size} errors." unless runner.errors.empty?
      end
      self
    end
  end
  RoodiTask.new('roodi', spec.files)
  task :gem => [:roodi]
rescue LoadError # don't bail out when people do not have roodi installed!
  task :roodi do
    puts 'please gem install roodi'
  end
end

desc "install gem globally"
task :install => [:gem] do
  sh "gem install pkg/#{spec.name}-#{spec.version}.gem"
end


begin
  require 'rdoc'
  require 'rdoc/task'
  RDoc::Task.new do |rd|
    rd.rdoc_files.include(spec.files)
  end
rescue LoadError => e
  task :rdoc do
    puts 'please gem install rdoc'
  end
end


require './rake_helper/perftools'

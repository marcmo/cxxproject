# -*- coding: undecided -*-
require 'rake/clean'

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
      desc "Check for design issues in: #{patterns.join(', ')}"        
      task name do
        runner = Roodi::Core::Runner.new
        runner.config = config if config
        patterns.each do |pattern|
          Dir.glob(pattern).each { |file| runner.check_file(file) }
        end
        runner.errors.each {|error| puts error}
#        raise "Found #{runner.errors.size} errors." unless runner.errors.empty?
      end
      self
    end
  end
  RoodiTask.new('roodi', spec.files)#, 'roodi.yaml')
  task :gem => [:roodi]
rescue LoadError # don't bail out when people do not have roodi installed!
  warn "roodi not installed...will not be checked!"
end

desc "Run all examples"
begin
  SPEC_PATTERN ='spec/**/*_spec.rb'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new() do |t|
    t.pattern = SPEC_PATTERN
  end
rescue LoadError
  begin
    require 'spec/rake/spectask'
    Spec::Rake::SpecTask.new() do |t|
      t.spec_files = SPEC_PATTERN
    end
  rescue LoadError
    task 'spec' do
      warn 'rspec not installed...will not be checked! please install gem install rspec'
    end
  end
end
task :gem => [:spec]

desc "install gem globally"
task :install => [:gem] do
  sh "gem install pkg/#{spec.name}-#{spec.version}.gem"
end

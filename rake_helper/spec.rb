SPEC_PATTERN ='spec/**/*_spec.rb'
require './lib/cxxproject/utils/optional'

def coverage
  load_rcov = lambda do
    require 'rcov'
    RSpec::Core::RakeTask.new(:coverage) do |t|
      t.pattern = SPEC_PATTERN
      t.rcov = true
      t.rcov_opts = ['--exclude', '.*/gems/.*']
    end
  end
  simple_cov_or_nothing = lambda do
    load_simplecov = lambda do
      require 'simplecov'
      task :coverage do
        ENV['COVERAGE'] = 'yes'
        Rake::Task['spec:spec'].invoke
      end
    end
    could_not_define_rcov_or_simplecov = lambda do
      task :coverage do
        puts "Please install coverage tools with\n\"gem install simplecov\" for ruby 1.9 or\n\"gem install rcov\" for ruby 1.8"
      end
    end
    Cxxproject::Utils::optional_package(load_simplecov, could_not_define_rcov_or_simplecov)
  end
  Cxxproject::Utils::optional_package(load_rcov, simple_cov_or_nothing)
end

def new_rspec
  require 'rspec/core/rake_task'
  desc "Run examples"
  RSpec::Core::RakeTask.new() do |t|
    t.pattern = SPEC_PATTERN
    if ENV['BUILD_SERVER']
      t.rspec_opts = '-r ./junit.rb -f JUnit -o build/test_details.xml'
    end
  end

  desc 'Run examples with coverage'
  coverage
  CLOBBER.include('coverage')
end

namespace :spec do
  new_rspec
end

task :spec do
  puts 'Please use spec:spec or spec:coverage'
end

task :gem => [:spec]

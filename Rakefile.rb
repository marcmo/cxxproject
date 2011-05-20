desc "Default Task"
task :default => [:install]


require 'rake/gempackagetask'
spec = Gem::Specification.load('cxx.gemspec')
Rake::GemPackageTask.new(spec) {|pkg|}


begin
  require 'roodi'
  require 'roodi_task'
  RoodiTask.new  'roodi', spec.files, 'roodi.yml'
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

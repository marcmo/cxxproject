require 'rake/gempackagetask'
begin
  require 'roodi'
  require 'roodi_task'
rescue LoadError # don't bail out when people do not have roodi installed!
  warn "roodi not installed...will not be checked!"
end

begin
  require 'spec/rake/spectask' # old rspec
rescue LoadError
  require 'rspec/core/rake_task' # rspec 2.5.x
  begin
  rescue LoadError # don't bail out when people do not have roodi installed!
    warn "spec not installed...will not be checked!"
  end
end



desc "Default Task"
task :default => [:install]

PKG_VERSION = '0.4.2'
PKG_FILES = FileList[
  'lib/**/*.rb',
  'Rakefile.rb',
  'spec/**/*.rb'
  #    'doc/**/*'
]

spec = Gem::Specification.new do |s|
  s.name = 'cxxproject'
  s.version = PKG_VERSION
  s.summary = "Cpp Support for Rake."
  s.description = <<-EOF
    Some more high level building blocks for cpp projects.
  EOF
  s.files = PKG_FILES.to_a
  s.require_path = 'lib'
  s.author = ''
  s.email = ''
  s.homepage = ''
  s.has_rdoc = true
end
Rake::GemPackageTask.new(spec) {|pkg|}

if self.class.const_defined?(:RoodiTask) then
  RoodiTask.new  'roodi', PKG_FILES, 'roodi.yml'
  task :gem => [:roodi]
end

# old rspec
if self.class.const_defined?(:SpecTask) then
  desc "Run all examples"
  Spec::Rake::SpecTask.new() do |t|
    t.spec_files = FileList['spec/**/*.rb']
  end
  task :gem => [:spec]
end

# new rspec
begin # const_defined? did not work?
  desc "Run all examples"
  RSpec::Core::RakeTask.new() do |t|
    t.pattern = 'spec/**/*.rb'
  end
  task :gem => [:spec]
rescue
end

desc "install gem globally"
task :install => [:gem] do
  sh "gem install pkg/#{spec.name}-#{spec.version}.gem"
end


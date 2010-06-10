require 'rake/gempackagetask'
begin
  require 'roodi' 
  require 'roodi_task'
  require 'spec/rake/spectask'
rescue LoadError
end

desc "Default Task"
task :default => [:install]

PKG_VERSION = '0.4'
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
	RoodiTask.new
	task :gem => [:roodi]
end

if self.class.const_defined?(:SpecTask) then
	desc "Run all examples"
	Spec::Rake::SpecTask.new() do |t|
	  t.spec_files = FileList['spec/**/*.rb']
	end
	task :gem => [:spec]
end

desc "install gem globally"
task :install => [:gem] do
  sh "gem install pkg/#{spec.name}-#{spec.version}.gem"
end


require 'rake/gempackagetask'
require 'roodi'
require 'roodi_task'
require 'spec/rake/spectask'

desc "Default Task"
task :default => [:package, :roodi]

PKG_VERSION = '0.1'
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
end

RoodiTask.new
Rake::GemPackageTask.new(spec) {|pkg|}

task :gem => [:spec, :roodi]

desc "Run all examples"
Spec::Rake::SpecTask.new() do |t|
  t.spec_files = FileList['spec/**/*.rb']
end

task :default => [:specs]

desc "install gem globally"
task :install => :gem do
  sh "sudo gem install pkg/#{spec.name}-#{spec.version}.gem"
end

desc "install2 gem privately"
task :install2 => :gem do
  sh "gem install pkg/#{spec.name}-#{spec.version}.gem"
end


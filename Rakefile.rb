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
  begin
		require 'rspec/core/rake_task' # rspec 2.5.x
  rescue LoadError
    warn "spec not installed...will not be checked!"
  end
end



desc "Default Task"
task :default => [:install]

PKG_FILES = FileList[
  'lib/**/*.rb',
  'lib/tools/**/*.template',
  'Rakefile.rb',
  'spec/**/*.rb'
]

task :gem
spec = Gem::Specification.load('cxx.gemspec')
Rake::GemPackageTask.new(spec)

if self.class.const_defined?(:RoodiTask) then
  RoodiTask.new  'roodi', PKG_FILES, 'roodi.yml'
  task :gem => [:roodi]
end

# old rspec
if self.class.const_defined?(:SpecTask) then
  desc "Run all examples"
  Spec::Rake::SpecTask.new() do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
  end
  task :gem => [:spec]
end

# new rspec
begin # const_defined? did not work?
  desc "Run all examples"
  RSpec::Core::RakeTask.new() do |t|
    puts Dir.glob 'spec/**/*_spec.rb'
    t.pattern = 'spec/**/*_spec.rb'
  end
  task :gem => [:spec]
rescue
end

desc 'build gem only'
task :gem_only do
  sh "gem build cxx.gemspec"
  mv FileList["*.gem"], "pkg"
end

desc "install gem globally"
task :install => [:gem] do
  sh "gem install pkg/#{spec.name}-#{spec.version}.gem"
end

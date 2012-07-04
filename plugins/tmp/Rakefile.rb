require 'rake/clean'

desc 'reinstall plugins'
task :reinstall do
  plugins = ["gcc","clang"]
  plugins.each do |p|
    sh "gem uninstall cxxproject_#{p}toolchain" 
    cd "toolchain#{p}" do
      sh "gem install #{p}.gemspec"
    end
  end
end

$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'
BuildDir = "BuildDir"

dependent_projects =  ['./project.rb']
CxxProject2Rake.new(dependent_projects, BuildDir, "clang", './')

$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'
BuildDir = "BuildDir"

dependent_projects =  ['./project.rb']
CxxProject2Rake.new(dependent_projects, BuildDir, "clang", './')

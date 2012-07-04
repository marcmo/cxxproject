$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'
BuildDir='output'
CxxProject2Rake.new(['project.rb'], BuildDir, "clang")

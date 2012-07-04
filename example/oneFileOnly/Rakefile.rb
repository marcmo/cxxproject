$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'
CxxProject2Rake.new(['project_compile.rb'], 'build', "gcc", '.')

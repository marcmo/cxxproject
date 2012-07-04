$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")

require 'cxxproject'
CxxProject2Rake.new(['basic/project.rb','lib1/project.rb','lib2/project.rb'] , "build", "clang", ".")

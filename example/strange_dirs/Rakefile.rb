$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")

require 'cxxproject'
CxxProject2Rake.new(Dir.glob('**/*project.rb'), "build", "gcc", ".")

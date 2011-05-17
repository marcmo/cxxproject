$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'
BuildDir='build'
CxxProject2Rake.new(Dir.glob('**/*project.rb'), BuildDir, GCCChain)


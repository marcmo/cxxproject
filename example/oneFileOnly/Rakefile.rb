$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'
BuildDir='build'
CxxProject2Rake.new(Dir.glob('project_compile.rb'), BuildDir, GCCChain)

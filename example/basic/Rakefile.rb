$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'

BuildDir="build"
toolchain = GCCChain
CxxProject2Rake.new(['basic/project.rb','lib1/project.rb','lib2/project.rb'] , BuildDir, toolchain)

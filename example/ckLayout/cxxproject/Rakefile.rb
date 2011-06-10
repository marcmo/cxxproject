$:.unshift File.join(File.dirname(__FILE__),'..', '..', '..','lib')

require 'cxxproject'
CxxProject2Rake.new(FileList['**/*project.rb'], "build", GCCChain, '..')

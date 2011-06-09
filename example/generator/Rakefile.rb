$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")

require 'cxxproject'

DIR = 'build/gen'
directory DIR

file File.join(DIR, 'test.cpp') => DIR do |t|
  sh "touch #{t.name}"
end

CxxProject2Rake.new('main/project.rb' , 'build', GCCChain, '.')

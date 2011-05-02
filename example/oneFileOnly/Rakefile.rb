$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'
CxxProject2Rake.new(Dir.glob('project_compile.rb'), Compiler.new('build'))

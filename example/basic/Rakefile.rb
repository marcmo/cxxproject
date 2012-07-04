$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
$:.unshift File.join(File.dirname(__FILE__),"..","..","plugins","toolchainclang","lib")

require 'cxxproject'
require 'clang'
# chain = GCCChain
puts "we are testing cxxproject version #{version_info}"
chain = CLANG_CHAIN
CxxProject2Rake.new(['basic/project.rb','lib1/project.rb','lib2/project.rb'] , "build", chain, ".")

$:.unshift File.join(File.dirname(__FILE__),"..","..","lib")
require 'cxxproject'

BuildDir="build"
toolchain = Cxxproject::Toolchain::GCCChain
CxxProject2Rake.new(Dir.glob('**/project.rb'), BuildDir, toolchain)
activate_ubigraph


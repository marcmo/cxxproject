# Just the default file wich is auto-required in the gem and which requires all needed stuff
require 'rubygems'
require 'yaml'
require 'rake/clean'

require 'cxxproject/utils/optional'

require 'cxxproject/ext/string'
require 'cxxproject/ext/hash'
require 'cxxproject/utils/utils'
require 'cxxproject/torake'
require 'cxxproject/utils/ubigraph'
require 'cxxproject/utils/graphstream'
require 'cxxproject/toolchain/provider'

require 'cxxproject/utils/progress'
require 'cxxproject/utils/rbcurse'
require 'cxxproject/utils/progress'
require 'cxxproject/utils/rbcurse'
require 'cxxproject/utils/stats'
require 'cxxproject/version'
require 'cxxproject/plugin_context'

require 'frazzle/frazzle'
registry = Frazzle::Registry.new('cxxproject', '_', '')

toolchain_plugins = registry.get_plugins('toolchain')
toolchain_plugins.each do |toolchain_plugin|
  puts "loading toolchain #{toolchain_plugin}"
  registry.load_plugin(toolchain_plugin, Cxxproject::PluginContext.new(nil, nil, nil))
end

include Cxxproject::Toolchain
CxxProject2Rake = Cxxproject::CxxProject2Rake
BinaryLibs = Cxxproject::BinaryLibs

def version_info
  Cxxproject::Version.cxxproject
end

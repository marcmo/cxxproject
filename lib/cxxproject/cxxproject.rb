# Just the default file wich is auto-required in the gem and which requires all needed stuff
require 'rubygems'
require 'yaml'
require 'rake/clean'


require 'cxxproject/ext/string'
require 'cxxproject/ext/hash'

require 'cxxproject/utils/optional'
require 'cxxproject/utils/utils'
require 'cxxproject/utils/stats'

require 'cxxproject/toolchain/provider'

require 'cxxproject/version'

require 'cxxproject/plugin_context'

require 'frazzle/frazzle'
registry = Frazzle::Registry.new('cxxproject', '_', '')

toolchain_plugins = registry.get_plugins('toolchain')
toolchain_plugins.each do |toolchain_plugin|
  registry.load_plugin(toolchain_plugin, Cxxproject::PluginContext.new(nil, nil, nil))
end

include Cxxproject::Toolchain

def version_info
  Cxxproject::Version.cxxproject
end

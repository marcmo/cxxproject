# Just the default file wich is auto-required in the gem and which requires all needed stuff
require 'rubygems'
require 'yaml'
require 'rake/clean'

require 'cxxproject/ext/hash'

require 'cxxproject/utils/optional'
require 'cxxproject/utils/utils'

require 'cxxproject/toolchain/provider'

require 'cxxproject/version'

require 'cxxproject/plugin_context'
require 'cxxproject/buildingblocks/building_blocks'

require 'frazzle/frazzle'
registry = Frazzle::Registry.new('cxxproject', '_', '')

plugins = registry.get_all_plugins
plugins.each do |plugin|
  registry.load_plugin(plugin, Cxxproject::PluginContext.create_no_args_context())
end

include Cxxproject::Toolchain

def version_info
  Cxxproject::Version.cxxproject
end

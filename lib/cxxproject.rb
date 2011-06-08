# Just the default file wich is auto-required in the gem and which requires all needed stuff
require 'rubygems'
require 'yaml'
require 'rake/clean'

require 'cxxproject/extensions/string_ext'
require 'cxxproject/utils/utils'
require 'cxxproject/torake'
require 'cxxproject/utils/ubigraph'
require 'cxxproject/utils/graphstream'
require 'cxxproject/toolchain/provider'
require 'cxxproject/utils/progress'

include Cxxproject::Toolchain

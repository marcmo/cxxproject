# Just the default file wich is auto-required in the gem and which requires all needed stuff
require 'rubygems'
require 'yaml'
require 'rake/clean'

require 'cxxproject/utils/optional'

require 'cxxproject/extensions/string_ext'
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

include Cxxproject::Toolchain

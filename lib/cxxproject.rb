# Just the default file wich is auto-required in the gem and which requires all needed stuff
require 'rubygems'
require 'yaml'
require 'rake/clean'

require 'cxxproject/utils/optional'

require 'cxxproject/ext/string'
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

include Cxxproject::Toolchain
CxxProject2Rake = Cxxproject::CxxProject2Rake
BinaryLibs = Cxxproject::BinaryLibs

def version_info
  Cxxproject::Version.cxxproject
end

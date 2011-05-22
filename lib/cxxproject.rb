# Just the default file wich is auto-required in the gem and which requires all needed stuff
require 'rubygems'
require 'yaml'
require 'rake/clean'

require 'cxxproject/extensions/string_ext'
require 'cxxproject/task_maker'
require 'cxxproject/utils/utils'
require 'cxxproject/torake'
require 'cxxproject/task_maker'
require 'cxxproject/torake/compiler'
require 'cxxproject/torake/gcccompiler'
require 'cxxproject/torake/osxcompiler'
require 'cxxproject/utils/ubigraph'
require 'cxxproject/utils/graphstream'

include Cxxproject::Toolchain


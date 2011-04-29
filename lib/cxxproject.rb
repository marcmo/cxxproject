# Just the default file wich is auto-required in the gem and which requires all needed stuff
require 'rubygems'
require 'yaml'
require 'rake/clean'

class String
  def remove_from_start(text)
    if index(text) == 0
      self[text.size..-1]
    else
      self
    end
  end
end


require 'cxxproject/alternative'
require 'cxxproject/utils'
require 'cxxproject/dependencies'
require 'cxxproject/configuration'
require 'cxxproject/buildingblock'
require 'cxxproject/torake'
require 'cxxproject/taskmaker'
require 'cxxproject/torake/gcccompiler'
require 'cxxproject/torake/osxcompiler'

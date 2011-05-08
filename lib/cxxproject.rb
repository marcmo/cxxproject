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


require 'cxxproject/task_maker'
require 'cxxproject/utils/utils'
require 'cxxproject/utils/ubigraph_support'
require 'cxxproject/torake'
require 'cxxproject/task_maker'
require 'cxxproject/torake/compiler'
require 'cxxproject/torake/gcccompiler'
require 'cxxproject/torake/osxcompiler'

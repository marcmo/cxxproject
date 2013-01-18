require 'cxxproject/context'
require 'cxxproject/toolchain/provider'

module Cxxproject
  # context in which plugins are evaluated
  # a cxx_plugin is a gem that:
  # - follows the naming convention cxxplugin_name
  # - that has a plugin.rb file in lib and
  # - that calls cxx_plugin
  #
  # the context contains
  # - @cxxproject2rake
  # - @building_blocks
  # - @log
  class PluginContext
    include Context

    def self.create_no_args_context
      return PluginContext.new(nil, nil, nil, 0)
    end

    def self.create_three_args_context(cxx, building_blocks, log)
      return PluginContext.new(cxx, building_blocks, log, 3)
    end

    def initialize(cxxproject2rake, building_blocks, log, expected_arity)
      @cxxproject2rake = cxxproject2rake
      @building_blocks = building_blocks
      @log = log
      @expected_arity = expected_arity
    end

    # method for plugins to get the
    # cxxproject2rake
    # building_blocks
    # log
    def cxx_plugin(&blk)
      if blk.arity != @expected_arity
        return
      end
    
      case blk.arity
      when 0
        blk.call()
      when 3
        blk.call(@cxxproject2rake, @building_blocks, @log)
      end
    end

    # specify a toolchain
    # hash supports:
    # * :command
    def toolchain(name, tc)
      raise "not a tc" unless tc.is_a?(Hash)
      check_hash(tc, Cxxproject::Toolchain::Provider.default.keys)
      check_compiler(tc[:COMPILER]) if tc[:COMPILER]
      check_linker(tc[:LINKER]) if tc[:LINKER]
      check_archiver(tc[:ARCHIVER]) if tc[:ARCHIVER]
      PluginContext::expand(tc)
      Cxxproject::Toolchain::Provider.add(name)
      Cxxproject::Toolchain::Provider.merge(Cxxproject::Toolchain::Provider[name], tc)
    end

    def self.expand(toolchain)
      to_expand = nil
      from = nil
      while (needs_expansion(toolchain)) do
        to_expand = find_toolchain_subhash(toolchain)
        from = find_toolchain_element(toolchain,to_expand[:BASED_ON])
        to_expand.delete(:BASED_ON)
        Cxxproject::Toolchain::Provider.merge(to_expand, from, false)
      end
      return toolchain
    end

    def self.needs_expansion(tc)
      res = false
      tc.each do |k,v|
        if k == :BASED_ON
          res = true
        elsif v.is_a?(Hash)
          res = needs_expansion(v)
        end
        if res
          break
        end
      end
      return res
    end

    def self.find_toolchain_subhash(tc)
      res = []
      loop = lambda do |res,tc|
        tc.each do |k,v|
          if(k == :BASED_ON)
            res << tc
          elsif v.is_a?(Hash)
            loop.call(res,v)
          end
        end
      end
      loop.call(res,tc)
      return res[0] if res.length > 0
    end


    def self.find_toolchain_element(tc,name)
      res = []
      loop = lambda do |res,tc,name|
        tc.each do |k,v|
          if k == name
            res << v
          elsif v.is_a?(Hash)
            loop.call(res,v,name)
          end
        end
      end
      loop.call(res,tc,name)
      return res[0] if res.length > 0
    end

    def check_compiler_hash(hash, sym)
      check_hash(hash[sym], Cxxproject::Toolchain::Provider.default[:COMPILER][sym].keys << :BASED_ON) if hash[sym]
    end
    def check_compiler(hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash, Cxxproject::Toolchain::Provider.default[:COMPILER].keys)
      [:CPP, :C, :ASM].each do |sym|
        check_compiler_hash(hash, sym)
      end
    end

    def check_linker(hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash, Cxxproject::Toolchain::Provider.default[:LINKER].keys)
    end

    def check_archiver(hash)
      raise "not a hash" unless hash.is_a?(Hash)
      check_hash(hash, Cxxproject::Toolchain::Provider.default[:ARCHIVER].keys)
    end

    # will use the content of the plugin.rb file and evaluate it
    # this will in turn result in a call to cxx_plugin
    def eval_plugin(plugin_text)
      instance_eval(plugin_text)
    end

  end

end

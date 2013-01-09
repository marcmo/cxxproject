require 'yaml'

class Toolchain

  attr_reader :toolchain

  def initialize(toolchain_file)
    @toolchain = YAML::load(File.open(toolchain_file))
    if @toolchain.base
      @based_on = @toolchain.base
    else
      @based_on = "base"
    end
    basechain = YAML::load(File.open(File.join(File.dirname(__FILE__),"#{@based_on}.json")))
    @toolchain = basechain.recursive_merge(@toolchain)
  end

  def method_missing(m, *args, &block)
    if @toolchain[m.to_s]
      self.class.send(:define_method, m) { @toolchain[m.to_s] }
      @toolchain[m.to_s]
    else
      return super
    end
  end

end

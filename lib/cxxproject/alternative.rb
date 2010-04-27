CxxConfigs = []

def cxx_configuration(*args, &block)
  c = EvalContext.new
  c.configuration(*args, &block)
end

class EvalContext

  def configuration(*args, &block)
    name = args[0]
    raise "no name given" unless name.is_a?(String) && !name.strip.empty?
    hash = args[1]
    raise "not a hash" unless hask.is_a?(Hash)
    @config = Configuration.new(name, hash[:source])
    @configs << @config
    instance_eval(&block)
  end

  def exe(*args)
    exe = Exe.new
    @config.addExe(exe)
  end
end

# # usage
# require 'cxxproject'
# 
# cxx_configuration "Test" do
#   exe "bla", :source => FileList[*.arxml]
#   lib "lib1", :source => "xxx/azzz/"
# end

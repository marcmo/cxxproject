require 'rake'

project_string = 'cxx_configuration "debug" do
  exe "basic",
    :sources => FileList.new("**/*.cpp"),
    :dependencies => ["2"]
  exe "debug",
    :sources => FileList.new("**/*.cpp"),
    :dependencies => ["abc"]
end'
# project_string = 'cxx_configuration "debug" do
#   [exe ("basic", :sources => FileList.new("**/*.cpp")),
#    exe ("next",{})]
# end'
class EvalContext

  attr_accessor :name, :myblock

  def cxx_configuration(name, &block)
    puts "calling cxx_configuration with name: #{name}"
    @myblock = block
    @name = name
  end

  def eval_project(project_text)
    instance_eval(project_text)
    puts "instance_eval with #{project_text}"
  end

  def configuration(*args, &block)
    name = args[0]
    raise "no name given" unless name.is_a?(String) && !name.strip.empty?
    instance_eval(&block)
  end

  def check_hash(hash,allowed)
    puts "hash" + hash.inspect
    hash.keys.map {|k| raise "#{k} is not a valid specifier!" unless allowed.include?(k) }
  end

  def exe(name, hash)
    puts "inside exe"
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes,:dependencies]
    puts "sources are: #{hash[:sources]}"
  end

  def source_lib(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes,:dependencies]
    raise ":sources need to be defined" unless hash.has_key?(:sources)
    puts "sources are: #{hash[:sources]}"
  end

  def compile(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes]
  end

end

loadContext = EvalContext.new
loadContext.eval_project(project_string)
loadContext.myblock.call()


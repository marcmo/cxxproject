require 'facets'

# Configuration provides hierarchical configuration data for each building block
# it searches for .cxxproject-file starting at the path of a project.rb file and 
# stopping at the filesystems root
class Configuration
  attr_reader :configs

  # initialize the hashes with a base_dir
  def initialize(base_dir)
    @configs = []
    Dir.ascend(base_dir) do |dir|
      file_name = File.join(dir, '.cxxproject')
      if File.exists?(file_name)
        @configs << file_name
      end
    end

    @values = {}
    @configs.reverse.each do |config|
      new_hash = YAML.load_file(config)
      if !new_hash.instance_of?(Hash)
        raise "wrong format of yaml: #{config} ... should be a hash"
      end
      @values.update(new_hash)
    end
  end

  # get the configvalue for key
  def get_value(key)
    return @values[key]
  end

  # simpe string rep
  def to_s
    res = "Configuration:"
    res += @values.to_s
    res
  end
end

require 'facets'

class Configuration
  attr_reader :configs
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

  def get_value(key)
    return @values[key]
  end
  def to_s
    res = "Configuration:"
    res += @values.to_s
    res
  end
end

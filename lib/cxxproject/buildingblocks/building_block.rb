require 'cxxproject/buildingblocks/has_dependencies_mixin'
require 'cxxproject/utils/graph'

# stores all defined buildingblocks by name (the name should be unique)
ALL_BUILDING_BLOCKS = {}

class BuildingBlock
  include HasDependencies

  attr_reader :name
  attr_reader :graph_name
  attr_reader :config_files
  attr_reader :project_dir
  attr_reader :output_dir

  def set_name(x)
    @name = x
    self
  end

  def set_tcs(x)
    @tcs = x
    self
  end

  def tcs()
    raise "Toolchain settings must be set before!" if @tcs.nil?
    @tcs
  end

  def set_config_files(x)
    @config_files = x
    self
  end

  def set_project_dir(x)
    @project_dir = x
    self
  end

  def set_output_dir(x)
    @output_dir = x
    self
  end

  def set_graph_name(x)
    @graph_name = x
    self
  end

  def initialize(name)
    @name = name
    @graph_name = name
    @config_files = []
    @project_dir = "."
    @output_dir = "."
    @tcs = nil

	raise "building block already exists: #{name}" if ALL_BUILDING_BLOCKS.include?@name
    ALL_BUILDING_BLOCKS[@name] = self
  end
  
  def complete_init()
  end

  def get_task_name()
    raise "this method must be implemented by decendants"
  end

end

require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'

class Executable < BuildingBlock
  include HasLibraries
  include HasSources

  attr_reader :linker_script
  attr_reader :mapfile
  attr_reader :output_file

  def set_linker_script(x)
    @linker_script = x
    self
  end

  def set_mapfile(x)
    @mapfile = x
    self
  end

  # set during creating the task - note: depends on the used tcs
  def set_output_file(x)
    @output_file = x
    self
  end

  def initialize(name)
    super(name)
    @linker_script = nil
    @mapfile = nil
  end

  def linker_libs_string
    @linkerString ||= ""
  end


  def get_executable_name()
    File.relFromTo(@complete_output_dir + "/" + @name + @tcs[:LINKER][:OUTPUT_ENDING], @project_dir)
  end

  def get_task_name()
    get_executable_name()
  end


end

require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'

class SourceLibrary < BuildingBlock
  include HasLibraries
  include HasSources

  def initialize(name)
    super(name)
  end

  def init_libs()
    @libs_with_path = [File.join(@output_dir,"lib#{name}.a")]
    puts "OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO init_libs: #{@libs_with_path.inspect}"
  end

  def get_archive_name()
    File.relFromTo(@project_dir + "/" + @output_dir + "/lib" + @name + ".a", @project_dir)
  end

  def get_task_name()
    get_archive_name
  end

end

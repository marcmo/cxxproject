require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'

class SourceLibrary < BuildingBlock
  include HasLibraries
  include HasSources

  def initialize(name)
    super(name)
    @search_for_lib = false # false: use libs_with_path ("Eclipse mode"), true: use libs_to_search and lib_searchpaths ("Linux mode")
  end

  def complete_init()
    if @search_for_lib
      libs_with_path << File.join(@output_dir,"lib#{@name}.a")
    else
      libs_to_search << @name
      lib_searchpaths << @output_dir
    end
  end

  def get_archive_name()
    File.relFromTo(@complete_output_dir + "/lib" + @name + ".a", @project_dir)
  end

  def set_search_for_lib(sfl)
    @search_for_lib = sfl
  end

  def get_task_name()
    get_archive_name
  end

end

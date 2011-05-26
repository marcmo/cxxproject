require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'

# can be used as wrapper for other tasks
class ModuleBuildingBlock < BuildingBlock
  include HasLibraries
  include HasSources

  def get_task_name()
    name
  end

  def create_internal()
    calc_compiler_strings()
    res = task get_task_name
    res.transparent_timestamp = true
    res
  end
end

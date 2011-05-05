require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'

class BinaryLibrary < BuildingBlock
  include HasLibraries

  def get_task_name()
    libs_to_search[0] # todo: should be more robust (not used in lake)
  end

end

require 'cxxproject/buildingblocks/building_block'

# can be used as wrapper for other tasks
class ModuleBuildingBlock < BuildingBlock

  def get_task_name()
    name
  end

end

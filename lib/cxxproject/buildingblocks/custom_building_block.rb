require 'cxxproject/buildingblocks/building_block'

# todo...

class CustomBuildingBlock < BuildingBlock
  attr_reader :custom_command

  def set_custom_command(c)
    @custom_command = c
    self
  end

  def get_task_name()
    raise "todo"
  end
  
end

require 'cxxproject/buildingblocks/building_block'

# todo...

class CustomBuildingBlock < BuildingBlock
  attr_reader :custom_command, :actions

  def set_custom_command(c)
    @custom_command = c
    self
  end

  def get_task_name()
    name
  end

  def set_actions(actions)
    if actions.kind_of?(Array)
      @actions = actions
    else
      @actions = [actions]
    end
  end

end

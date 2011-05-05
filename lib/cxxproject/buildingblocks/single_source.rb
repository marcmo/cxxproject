require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_sources_mixin'

class SingleSource < BuildingBlock
  include HasSources

  def get_task_name()
    "multitask_#{name}" # see create_tasks_for_building_block of TaskMaker
  end

end

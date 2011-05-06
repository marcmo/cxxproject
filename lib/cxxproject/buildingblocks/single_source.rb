require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_sources_mixin'

class SingleSource < BuildingBlock
  include HasSources

  def get_task_name()
    get_sources_task_name
  end

end

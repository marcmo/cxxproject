require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_sources_mixin'

class SingleSource < BuildingBlock
  include HasSources

  def get_task_name()
    get_sources_task_name
  end


  def create()
  
    calc_compiler_strings()
    object_tasks, objects_multitask = create_tasks_for_objects()
  
    res = nil
    if objects_multitask
      res = objects_multitask
      namespace "compile" do
        desc "compile sources in #{@name}-configuration"
        task @name => objects_multitask
      end
      objects_multitask.add_description("compile sources only")
    end
    res
  end

end

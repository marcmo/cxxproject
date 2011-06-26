require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'

module Cxxproject
  class SingleSource < BuildingBlock
    include HasSources
    include HasIncludes

    def initialize(name)
      super(name)
      @addOnlyFilesToCleanTask = true
    end

    def get_task_name()
      get_sources_task_name
    end


    def convert_to_rake()
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

      setup_rake_dependencies(res)
      res
    end

  end
end

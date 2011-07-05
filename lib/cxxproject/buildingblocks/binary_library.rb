require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'

module Cxxproject

  class BinaryLibrary < BuildingBlock
    include HasLibraries
    include HasIncludes

    def initialize(name, useNameAsLib = true)
      super(name)
      @useNameAsLib = useNameAsLib
      libs_to_search << name if @useNameAsLib
    end

    def get_task_name()
      return libs_to_search[0] if @useNameAsLib
      @name
    end


    def convert_to_rake()
      res = task get_task_name
      def res.needed?
        return false
      end
      res.transparent_timestamp = true
      res.type = Rake::Task::BINARY
      setup_rake_dependencies(res)
      res
    end

  end
end

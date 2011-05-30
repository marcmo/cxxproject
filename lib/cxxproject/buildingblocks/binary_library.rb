require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'

class BinaryLibrary < BuildingBlock
  include HasLibraries

  def initialize(name)
    super(name)
    libs_to_search << name
  end

  def get_task_name()
    libs_to_search[0]
  end


  def convert_to_rake()
    res = task get_task_name
    def res.needed?
      return false
    end
    res.transparent_timestamp = true
    setup_cleantask
    setup_rake_dependencies(res)
    res
  end

end

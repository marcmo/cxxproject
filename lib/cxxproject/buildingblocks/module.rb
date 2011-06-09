require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'


# can be used as wrapper for other tasks
class ModuleBuildingBlock < BuildingBlock
  include HasLibraries
  include HasSources
  include HasIncludes

  attr_accessor :content

  def initialize(name)
    super
    content = []
  end

  def get_task_name()
    name
  end

  def convert_to_rake()
    calc_compiler_strings()
    res = task get_task_name
    res.type = Rake::Task::MODULE
    res.transparent_timestamp = true

    setup_rake_dependencies(res)
    res
  end
end

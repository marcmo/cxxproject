require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'

class Makefile < BuildingBlock
  include HasLibraries

  def set_target(x)
    @target = x
    self
  end

  def set_makefile(x)
    @makefile = x
    self
  end

  def get_makefile
    File.relFromTo(@makefile, @project_dir)
  end

  def get_target
    @target
  end

  def initialize(name)
    super(name)
    @target = "all"
    @makefile = nil
  end

  def get_task_name()
    get_makefile+"_"+get_target
  end

end

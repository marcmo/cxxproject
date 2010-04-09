require 'cxxproject/dependencies'

ALL_BUILDING_BLOCKS = {}

class BuildingBlock
  attr_accessor :name, :base, :dependencies, :libs
  def initialize(name)
    @name = name
    @dependencies = []
    @libs = []
    ALL_BUILDING_BLOCKS[@name] = self
  end
  def to_s
    inspect
  end
end

class SourceBuildingBlock < BuildingBlock
  attr_accessor :sources, :includes

  def initialize(name)
    super(name)
    @sources = []
    @includes = ['.']
    @dependencies = []
  end
end

class SourceLibrary < SourceBuildingBlock
  attr_accessor :defines
  def initialize(name)
    super(name)
    @defines = []
  end
end

SourceLibrary.new('testip')
class Exe < SourceBuildingBlock
  def initialize(name)
    super(name)
  end
end

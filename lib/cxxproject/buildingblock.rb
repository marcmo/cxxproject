# stores all defined buildingblocks by name (the name should be unique)
ALL_BUILDING_BLOCKS = {}



class BuildingBlock
  attr_accessor :name, :base
  attr_reader :config, :dependencies

  def initialize(config, name)
    @name = name
    @dependencies = []
    @config = config
    ALL_BUILDING_BLOCKS[@name] = self
  end

  def set_dependencies(deps)
    @dependencies = deps.map do |dep|
      if dep.instance_of?(String)
        dep
      else
        dep.name
      end
    end
    self
  end
end

class LibraryBuildingBlock < BuildingBlock
  attr_reader :includes
  def initialize(config, name)
    super
  end
  def set_includes(i)
    i.each { |f| raise "include folder does not exist #{f}" unless File.exist?(f)}
    @includes = i
    self
  end
end

class SourceBuildingBlock < LibraryBuildingBlock
  attr_reader :sources

  def initialize(config, name)
    super
    @sources = []
    @dependencies = []
  end
  def to_s
    s = "#{super} sources: "
    @sources.each_with_index do |source, i|
      if i != 0
        s = s + ', '
      end
      s = s + source
    end
    s
  end
  def set_sources(s)
    s.each { |f| raise "source file does not exist #{f}" unless File.exist?(f)}
    @sources = s
    self
  end
end

class SourceLibrary < SourceBuildingBlock
  def initialize(config, name)
    super
  end
end

class Exe < SourceBuildingBlock
  def initialize(config, name)
    super
  end
end

class BinaryLibrary < LibraryBuildingBlock
  def initialize(config, name)
    super
    @includes = nil
  end
end

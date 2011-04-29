# stores all defined buildingblocks by name (the name should be unique)
ALL_BUILDING_BLOCKS = {}



class BuildingBlock
  attr_accessor :name, :base
  attr_reader :dependencies
  attr_accessor :compiler
  attr_accessor :lib
  attr_accessor :base
  attr_accessor :outdir

  def initialize(name)
    @name = name
    @dependencies = []
    ALL_BUILDING_BLOCKS[@name] = self
    puts "initialize buildingblock, all was: #{ALL_BUILDING_BLOCKS.inspect}"
  end

  def set_dependencies(deps)
    puts "set_dependencies ...#{deps.inspect}"
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
  def initialize(name)
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

  def initialize(name)
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
    pwd = `pwd`
    s.each { |f| raise "missing #{f} (current dir: #{pwd})" unless File.exist?(f)}
    @sources = s
    self
  end
end

class SourceLibrary < SourceBuildingBlock
  def initialize(name)
    super
  end
end

class Exe < SourceBuildingBlock
  def initialize(name)
    super
  end
end

class BinaryLibrary < LibraryBuildingBlock
  def initialize(name)
    super
    @includes = nil
  end
end

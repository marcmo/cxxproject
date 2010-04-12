# dependency calculator for building blocks
# should be used like: Dependencies.transitive_dependencies(building_block)
class Dependencies

  attr_reader :all_libs

  def self.transitive_dependencies(lib)
    return Dependencies.new(lib).all_libs
  end

private

  def initialize(lib_strings)
    @all_libs = []
    lib_strings.each do |lib_string|
      add(lib_string)
    end
  end

  def add_unique(lib)
    @all_libs.delete(lib)
    @all_libs.push(lib)
  end

  def add(lib)
    bb = ALL_BUILDING_BLOCKS[lib]
    if !bb
      raise "dependency not found #{lib}"
    end
    add_unique(bb)
    bb.dependencies.each do |dep|
      add(dep)
    end
  end

end

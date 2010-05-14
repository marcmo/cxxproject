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
      add_dependent_lib(lib_string)
    end
  end

  def push_to_end(lib)
    @all_libs.delete(lib)
    @all_libs.push(lib)
  end

  def add_dependent_lib(lib)
    if (lib.instance_of?(BinaryLibrary))
      bb = lib
      raise "lib should already be a building block" unless ALL_BUILDING_BLOCKS[lib.name] == bb
    else
      bb = ALL_BUILDING_BLOCKS[lib]
    end
    if !bb
      raise "dependency not found #{lib}"
    end
    push_to_end(bb)
    bb.dependencies.each do |dep|
      add_dependent_lib(dep)
    end
  end

end

require 'cxxproject/utils/dot/graph_writer'

class BuildingBlockGraphWriter < GraphWriter

  private

  def write_node(node)
    @dotFile.write("  \"#{node.name}\"\n")
  end

  def write_transition(node, dep)
    @dotFile.write("  \"#{node.name}\" -> \"#{dep.name}\"\n")
  end

  def get_deps(node)
    return node.dependencies.map { |depName| ALL_BUILDING_BLOCKS[depName] }
  end

end

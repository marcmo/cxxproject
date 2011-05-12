class GraphWriter

  NO = 0
  DETAIL = 1
  YES = 2

  def write_graph(filename,startNodes)
    @filename = filename
    start_graph
    @writtenNodes = []
    startNodes.each { |n| write_step(n) }
    end_graph
  end

  private

  def write_step(node)
    return if @writtenNodes.include? node
    @writtenNodes << node

    write_node(node)

    get_deps(node).each do |dep|
      write_transition(node, dep)
      write_step(dep)
    end
  end

  def start_graph
    puts "\nWriting dot-file #{@filename}...\n"
    @dotFile = File.new(@filename, "w")
    @dotFile.write("digraph TaskGraph\n");
    @dotFile.write("{\n");
  end

  def end_graph
    @dotFile.write("}\n");
    @dotFile.close()
  end

  def write_node(node)
    raise "Must be implemented by descendants"
  end

  def write_transition(node, dep)
    raise "Must be implemented by descendants"
  end

  def get_deps(node)
    raise "Must be implemented by descendants"
  end

end


class ModuleGraphWriter < GraphWriter

  def write_graph(filename,startNodes,orgDeps = true)
    @orgDeps = orgDeps
    super(filename,startNodes)
  end

  private

  def start_graph
    super
    @dotFile.write("node [shape=plaintext]\n")
  end

  def write_node(node)

    if node.instance_of?ModuleBuildingBlock
      @dotFile.write("  \"#{node.graph_name}\" [label=<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\"> <TR><TD bgcolor=\"#DDDDDD\">#{node.graph_name}</TD></TR>")
	     content = []
		 node.content.each do |dep|
		   @dotFile.write("<TR><TD>#{dep.graph_name}</TD></TR>")
		 end
      @dotFile.write("</TABLE>>];\n")

      depList = get_deps(node)
      depList.each do |dNode|
        if dNode.instance_of?ModuleBuildingBlock
          @dotFile.write("  \"#{node.graph_name}\" -> \"#{dNode.graph_name}\"\n")
        end
      end
    end

  end

  def write_transition(node, dep)
  end

  def get_deps(n)
    return [] if not n.instance_of?ModuleBuildingBlock
    depList = @orgDeps ? n.mmDepNodeOrg.helper_dependencies : n.mmDepNodeRed.dependencies
    return depList.map { |depName| ALL_BUILDING_BLOCKS[depName] }
  end

end


class BuildingBlockGraphWriter < GraphWriter

  private

  def write_node(node)
    @dotFile.write("  \"#{node.graph_name}\"\n")
  end

  def write_transition(node, dep)
    @dotFile.write("  \"#{node.graph_name}\" -> \"#{dep.graph_name}\"\n")
  end

  def get_deps(node)
    return node.dependencies.map { |depName| ALL_BUILDING_BLOCKS[depName] }
  end

end

class TaskGraphWriter < GraphWriter

  def write_graph(filename,startNodes,detailTasks = false)
    @detailTasks = detailTasks ? GraphWriter::DETAIL : GraphWriter::YES
    super(filename,startNodes)
  end

  private

  def get_deps(node)
    deps = []
    if node.showInGraph == GraphWriter::YES
      node.prerequisites.each do |p|
        task = Rake.application.lookup(p)
        if (task)
          next if task.showInGraph < @detailTasks
          deps << task
        end
      end
    end
    deps
  end

  def write_node(node)
    @dotFile.write("  \"#{node.name}\"\n")
  end

  def write_transition(node, dep)
    @dotFile.write("  \"#{node.name}\" -> \"#{dep.name}\"\n")
  end

end

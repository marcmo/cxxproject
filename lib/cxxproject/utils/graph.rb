class GraphWriter

  NO = 0
  DETAIL = 1
  YES = 2

  def writeGraph(filename,startNodes)
    @filename = filename
    startGraph
    @writtenNodes = []
    startNodes.each { |n| writeStep(n) }
    endGraph
  end

  private

  def writeStep(node)
    return if @writtenNodes.include? node
    @writtenNodes << node

    writeNode(node)

    getDeps(node).each do |dep|
      writeTransition(node, dep)
      writeStep(dep)
    end
  end

  def startGraph
    puts "\nWriting dot-file #{@filename}...\n"
    @dotFile = File.new(@filename, "w")
    @dotFile.write("digraph TaskGraph\n");
    @dotFile.write("{\n");
  end

  def endGraph
    @dotFile.write("}\n");
    @dotFile.close()
  end

  def writeNode(node)
    raise "Must be implemented by descendants"
  end

  def writeTransition(node, dep)
    raise "Must be implemented by descendants"
  end

  def getDeps(node)
    raise "Must be implemented by descendants"
  end

end


class ModuleGraphWriter < GraphWriter

  def writeGraph(filename,startNodes,orgDeps = true)
    @orgDeps = orgDeps # orgDeps is with dependencies, otherwise task_prerequisites is used as dependency list
    super(filename,startNodes)
  end

  private

  def startGraph
    super
    @dotFile.write("node [shape=plaintext]\n")
  end

  def writeNode(node)

    if node.instance_of?ModuleBuildingBlock
      @dotFile.write("  \"#{node.graph_name}\" [label=<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\"> <TR><TD bgcolor=\"#DDDDDD\">#{node.graph_name}</TD></TR>")
	     content = []
		 node.content.each do |dep|
		   @dotFile.write("<TR><TD>#{dep.graph_name}</TD></TR>")
		 end
      @dotFile.write("</TABLE>>];\n")

      depList = getDeps(node.mmDepNode)
      depList.each do |dNode|
        if dNode.instance_of?ModuleBuildingBlock
          @dotFile.write("  \"#{node.graph_name}\" -> \"#{dNode.graph_name}\"\n")
        end
      end
    end

  end

  def writeTransition(node, dep)
  end

  def getDeps(node)
    depList = @orgDeps? node.dependencies : node.task_prerequisites[1..-1]
    return depList.map { |depName| ALL_BUILDING_BLOCKS[depName] }
  end

end


class BuildingBlockGraphWriter < GraphWriter

  private

  def writeNode(node)
    @dotFile.write("  \"#{node.graph_name}\"\n")
  end

  def writeTransition(node, dep)
    @dotFile.write("  \"#{node.graph_name}\" -> \"#{dep.graph_name}\"\n")
  end

  def getDeps(node)
    return node.dependencies.map { |depName| ALL_BUILDING_BLOCKS[depName] }
  end

end

class TaskGraphWriter < GraphWriter

  def writeGraph(filename,startNodes,detailTasks = false)
    @detailTasks = detailTasks ? GraphWriter::DETAIL : GraphWriter::YES
  	super(filename,startNodes)
  end

  private

  def getDeps(node)
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

  def writeNode(node)
    @dotFile.write("  \"#{node.name}\"\n")
  end

  def writeTransition(node, dep)
    @dotFile.write("  \"#{node.name}\" -> \"#{dep.name}\"\n")
  end

end

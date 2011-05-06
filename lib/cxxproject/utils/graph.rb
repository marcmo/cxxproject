class GraphWriter

  def writeGraph(startNodes)
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
    puts "\nWriting dot-file graph.dot...\n"
    @dotFile = File.new("tasks.dot", "w")
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


class BuildingBlockGraphWriter < GraphWriter

  def initialize(moduleMode = false)
  	@moduleMode = moduleMode # moduleMode is used by lake
  end

private
  
  def startGraph
    super
    @dotFile.write("node [shape=plaintext]\n") if @moduleMode
  end
  
  
  def writeNode(node)
  	
    if (@moduleMode)
        if node.instance_of?ModuleBuildingBlock
		    @dotFile.write("  \"#{node.graph_name}\" [label=<<TABLE BORDER=\"0\" CELLBORDER=\"1\" CELLSPACING=\"0\"> <TR><TD bgcolor=\"#DDDDDD\">#{node.graph_name}</TD></TR>")
		    node.dependencies.each do |depName|
		        dep = ALL_BUILDING_BLOCKS[depName]
		    	@dotFile.write("<TR><TD>#{dep.graph_name}</TD></TR>") if not dep.instance_of?ModuleBuildingBlock
		    end
		    @dotFile.write("</TABLE>>];\n")
		end  	
	else  	
		@dotFile.write("  \"#{node.graph_name}\"\n")
	end
  end
	
  def writeTransition(node, dep)
    if not @moduleMode or (node.instance_of?ModuleBuildingBlock and dep.instance_of?ModuleBuildingBlock)
   	  @dotFile.write("  \"#{node.graph_name}\" -> \"#{dep.graph_name}\"\n")
    end
  end  
  
  def getDeps(node)
    return node.dependencies.map { |depName| ALL_BUILDING_BLOCKS[depName] }
  end
  

end


class TaskGraphWriter < GraphWriter

  def initialize(allTasks = false)
  	@allTasks = allTasks # allTasks means write also tasks which are marked with showInGraph = false
  end
  
private
  
  def getDeps(node)
    deps = []
    node.prerequisites.each do |p|
	  	task = Rake.application.lookup(p)
	  	if (task)
	  		next if not @allTasks and not task.showInGraph
			deps << task    
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

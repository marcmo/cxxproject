class GraphWriter

  def writeGraph(startNode)
	startGraph
	@writtenNodes = []
	writeStep(startNode)
	endGraph  
  end

private

  def writeStep(node)
	return if @writtenNodes.include? node
	@writtenNodes << nodes
	
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
	@dotFile.write("  \"node.name\"")
  end
  	
  def writeTransition(node, dep)
   	@dotFile.write("  \"node.name\" -> \"dep.name\"")
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
  
  def writeNode(node)
  	
    if (@moduleMode)
	    @dotFile.write("  \"#{node.name}\" <<TABLE BORDER="0" CELLBORDER="1" CELLSPACING="0"> <TR><TD bgcolor=\"#DDDDDD\">\"#{node.name}\"</TD></TR>")
	    bb.dependencies.each do |depName|
	        dep = ALL_BUILDING_BLOCKS[depName]
	    	@dotFile.write("<TR><TD>#{dep.name}</TD></TR>") if not dep.instance_of?ModuleBuildingBlock
	    end
	    @dotFile.write("</TABLE>>];\n")  	
	else  	
		super(node)
	end
  end
	
  def writeTransition(node, dep)
    if not @moduleMode or (node.instance_of?ModuleBuildingBlock and dep.instance_of?ModuleBuildingBlock)
    	super(node, dep)
    end
  end  
  
  def getDeps(node)
    return node.dependencies.map { |depName| ALL_BUILDING_BLOCKS[depName] }
  end
  

end


class TaskGraphWriter < GraphWriter

  def initialize(allTasks = false, withFiles = false)
  	@allTasks = allTasks # allTasks means write also tasks which are marked with showInGraph = false
  	@withFiles = withFiles # shows dependencies to non-tasks like heaeder files
  end
  
private
  
  def getDeps(node)
    deps = []
    node.prerequisites.each do |p|
	  	task = Rake.application.lookup(p)
	  	if (task)
	  		next if not @allTasks and not @task.showInGraph
	  	else
	  		next if not @withFiles
	  		task = Rake.application.synthesize_file_task(p)
	  	end
		deps << task if task    
    end
  end

end

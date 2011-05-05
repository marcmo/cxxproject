require 'cxxproject/toolchain/settings'

class GraphWriter

  YES = 0
  OBJ = 1
  HELPER = 2
  NO = 3

end

=begin

# - assumes that working dir is a project dir and workspace dir is "../"
# - only tasks with showInGraph==true are printed out (.exe, .a, .o, .o.d, make)
class GraphWriter

  YES = 0
  OBJ = 1
  HELPER = 2
  NO = 3

  def initialize(startTask, level)
    @startTask = startTask
    @level = level
  end


  def startGraph
    puts "\nWriting dot-file graph.dot...\n"
    @dotFile = File.new("tasks.dot", "w")
    @dotFile.write("digraph TaskGraph\n");
    @dotFile.write("{\n");
#    @dotFile.write("  rankdir=LR;\n");
#    @dotFile.write("  \"#{@startTask.name}\"\n");
  end
      
  def endGraph
    @dotFile.write("}\n");
    @dotFile.close()
  end

  def writeGraph
    @dottedTasks = Set.new

    puts "\nWriting dot-file graph.dot...\n"
    @dotFile = File.new("tasks.dot", "w")
    @dotFile.write("digraph TaskGraph\n");
    @dotFile.write("{\n");
    @dotFile.write("  rankdir=LR;\n");
    @dotFile.write("  \"#{@startTask.name}\"\n");

	tmp = @startTask.showInGraph
	@startTask.showInGraph = GraphWriter::YES
    dotSubTasks(@startTask, true)
    @startTask.showInGraph = tmp


  end

  private

  def makeDotName(pr)
    #
    #if pr.name.include? "MultiTask"
    #  toname = pr.name
    #elsif pr.name.length > 3 and pr.name[0..2] == "../"
    #  toName = pr.name[3..-1]
    #else
    #  toName = @startupProjectSettings.config.name + "/" + pr.name
    #end
  end

  def calcDeps(deps, d, readTasks)
    return if readTasks.include? d
    readTasks << d
    if d.showInGraph > @level
      (d.prerequisites+d.dismissed_prerequisites).each do |sub|
		x = d.application[sub, d.scope]
        calcDeps(deps, x, readTasks)
      end
    else
      deps << d
    end
  end
 
  
	def dotSubTasks(t, start = false)
		return if @dottedTasks.include? t.name
		@dottedTasks << t.name
		
		if start
			@dotFile.write("  \"#{t.name}\" [shape=")
        	@dotFile.write("doubleoctagon]\n") 
	    elsif t.showInGraph <= @level
	        @dotFile.write("  \"#{t.name}\" [shape=")
		    @dotFile.write("box]\n") if t.showInGraph == GraphWriter::YES
			@dotFile.write("ellipse]\n") if t.showInGraph == GraphWriter::OBJ
			@dotFile.write("folder]\n") if t.showInGraph == GraphWriter::HELPER
			@dotFile.write("note]\n") if t.showInGraph == GraphWriter::NO
		end
		
		(t.prerequisites+t.dismissed_prerequisites).each do |d|
		    x = t.application[d, t.scope]
		    if t.showInGraph <= @level
			    deps = []
			    calcDeps(deps, x, [t])
			    deps.each do |dep|
					@dotFile.write("  \"#{t.name}\" -> \"#{dep.name}\"\n");
				end
			end
			dotSubTasks(x)
		end
	end  

end


class ModuleGraphWriter
  
  def writeGraph(startBB, withSubModules = true)
	startGraph
	
	bbWriten = []
	writeNode(startBB, bbWriten)
	
	endGraph  
  end
  
  def writeNode(bb, bbWriten)
	return if bbWriten.include? bb
	bbWriten << bb
  
  
    struct3 [label="{ b | c | f}];
  
	@dotFile.write("  \"#{bb.name}\" [shape=folder]\n")
	
	
  	@dotFile.write("box]\n") if t.showInGraph == GraphWriter::YES
  
  end
  

end

=end


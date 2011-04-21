require 'cxxproject/toolchain/settings'

# - assumes that working dir is a project dir and workspace dir is "../"
# - only tasks with showInGraph==true are printed out (.exe, .a, .o, .o.d, make) 
class GraphWriter 

	def initialize(startTask, startupProjectSettings)
		@startupProjectSettings = startupProjectSettings
		@startTask = startTask
	end

	def writeGraph
		@dottedTasks = Set.new
		
		puts "\nWriting dot-file graph.dot...\n"
		@dotFile = File.new("tasks.dot", "w")
		@dotFile.write("digraph TaskGraph\n");
		@dotFile.write("{\n");
		@dotFile.write("  rankdir=LR;\n");
		@dotFile.write("  \"#{makeDotName(@startTask)}\"\n");
		dotSubTasks(@startTask)
		@dotFile.write("}\n");
		@dotFile.close()
	end
	
	private
	
	def makeDotName(pr)
		if pr.name.length > 3 and pr.name[0..2] == "../"
			toName = pr.name[3..-1]
		else
			toName = @startupProjectSettings.config.name + "/" + pr.name
		end
	end		
	
	def dotSubTasks(t)
		return if @dottedTasks.include? t.name
		@dottedTasks << t.name
		t.prerequisites.each do |d|
		    x = t.application[d, t.scope]
		    if t.showInGraph and x.showInGraph
				@dotFile.write("  \"#{makeDotName(t)}\" -> \"#{makeDotName(x)}\"\n");
			end
			dotSubTasks(x)
		end
	end

end


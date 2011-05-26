require 'cxxproject/utils/dot/graph_writer'

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

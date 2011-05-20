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

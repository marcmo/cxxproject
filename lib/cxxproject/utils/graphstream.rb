begin
  require 'socket'

  def apply?(name)
    name.match(/.*\.apply\Z/) != nil
  end

  class GraphStream
    def self.init
      @@server = TCPSocket.open('localhost', 31217)
    end
    def self.clear
      @@server.puts('Clear()')
    end
    def self.set_stylesheet(s)
      @@server.puts("SetStylesheet(#{s})")
    end
    def self.add_vertex(id)
      @@server.puts("AddVertex(#{id})")
    end
    def self.add_edge(from, to)
      @@server.puts("AddEdge(#{from},#{to})")
    end
    def self.set_class(id, clazz)
      @@server.puts("SetClass(#{id},#{clazz})")
    end
  end

  class GraphStreamSupport

    def object?(name)
      name.match(/.*\.o\Z/) != nil
    end

    def exe?(name)
      name.match(/.*\.exe\Z/) != nil
    end
    def library?(name)
      name.match(/.*\.a\Z/) != nil
    end
    def multitask?(name)
      name.index("Sources") == 0
    end
    def interesting?(name)
      exe?(name) || object?(name) || library?(name) || multitask?(name)
    end

    def initialize
      Rake::Task.tasks.each do |t|
        if apply?(t.name)
          t.invoke
        end
      end

      interesting_tasks = Rake::Task.tasks.select { |i| interesting?(i.name) }
      @vertices = {}
      interesting_tasks.each do |task|
        @vertices[task.name] = task
        GraphStream.add_vertex(task.name)
      end

      # create edges
      interesting_tasks.each do |task|
        from = task.name
        task.prerequisites.each do |to|
          GraphStream.add_edge(from, to)
        end
      end

      @vertices.each do |name, task|
        set_attributes(name, task)
      end

    end

#    def update_colors
#      @vertices.each_key do |k|
#        set_attributes(v, k)
#      end
#    end

    def set_attributes(name, task)
      GraphStream.set_class(name, state2color(task))
#      v.v.color = state2color(name)
#      v.v.shape = name2shape(name)
#      v.v.size = name2size(name)
    end

 #   def name2shape(name)
 #     if object?(name)
 #       return 'cube'
 #     elsif exe?(name)
 #       return 'sphere'
 #     elsif multitask?(name)
 #       return 'torus'
 #     else
 #       return 'octahedron'
 #     end
 #   end
 #   def name2size(name)
 #     if object?(name)
 #       return 0.7
 #     elsif exe?(name)
 #       return 1.2
 #     else
 #       return 1.0
 #     end
 #   end
   def state2color(t)
      begin
        if t.dirty?
          return 'dirty'
        else
          return 'ready'
        end
      rescue StandardError => bang
        puts bang
        return '#ff00ff'
      end
    end

    def update(name, color)
      GraphStream.set_class(name, color)
    end

    def before_prerequisites(name)
      update(name, 'before_prerequisites')
    end

    def after_prerequisites(name)
      update(name, 'after_prerequisites')
    end

    def before_execute(name)
      update(name, 'before_execute')
    end

    def after_execute(name)
      update(name, 'after_execute')
    end
  end

  namespace :graphstream do
    task :init do
      GraphStream.init
      GraphStream.set_stylesheet('node {fill-color:green;}node.dirty{fill-color:red;}node.before_prerequisites{fill-color:yellow;}node.after_prerequisites{fill-color:orange;}node.before_execute{fill-color:blue;}node.after_execute{fill-color:green;}node.ready{fill-color:black;}')
    end

    desc 'clear graphstream'
    task :clear => :init do
      GraphStream.clear
    end

    desc 'update graphstream'
    task :update => :init do
      begin
        require 'cxxproject/extensions/rake_listener_ext'
        require 'cxxproject/extensions/rake_dirty_ext'
        Rake::add_listener(GraphStreamSupport.new)
      rescue StandardError => e
        puts e
      end
    end
  end
rescue Exception => e
  puts e
end

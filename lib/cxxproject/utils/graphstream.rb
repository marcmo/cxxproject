begin
  require 'socket'

  def apply?(name)
    name.match(/.*\.apply\Z/) != nil
  end

  class GraphStream
    def self.init
      begin
        @@server = TCPSocket.open('localhost', 31217)
      rescue Exception => bang
        puts bang
      end
    end
    def self.send(command)
      #      puts command
      @@server.puts(command)
    end

    def self.clear
      send('Clear()')
    end

    def self.set_stylesheet(s)
      send("SetStylesheet(#{s})")
    end
    def self.add_vertex(id)
      send("AddVertex(#{id})")
    end
    def self.add_edge(from, to)
      send("AddEdge(#{from},#{to})")
    end
    def self.set_class(id, clazz)
      send("SetClass(#{id},#{clazz})")
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

    def set_attributes(name, task)
      GraphStream.set_class(name, state2color(task))
    end

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
    end

    desc 'clear graphstream'
    task :clear => :init do
      GraphStream.clear
    end

    desc 'update graphstream'
    task :update => :init do
      GraphStream.set_stylesheet('node {fill-color:green;}node.dirty{fill-color:red;}node.before_prerequisites{fill-color:yellow;}node.after_prerequisites{fill-color:orange;}node.before_execute{fill-color:blue;}node.after_execute{fill-color:green;}node.ready{fill-color:yellow;}')
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

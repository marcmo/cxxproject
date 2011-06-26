module Cxxproject
  module Utils
    define_graphstream = lambda do
      require 'socket'
      require 'thread'

      class GraphStream
        def initialize
          begin
            @server = TCPSocket.open('localhost', 31217)
            @queue = Queue.new
            Thread.new do
              while true
                command = @queue.pop
                @server.puts(command)
              end
            end
          rescue Exception => bang
            puts bang
          end
        end
        def send(command)
          @queue << command
        end

        def clear
          send('Clear()')
        end

        def set_stylesheet(s)
          send("SetStylesheet(#{s})")
        end
        def add_vertex(id)
          send("AddVertex(#{id})")
        end
        def add_edge(from, to)
          send("AddEdge(#{from},#{to})")
        end
        def set_class(id, clazz)
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
          name.index("Objects of") == 0
        end
        def interesting?(name)
          exe?(name) || object?(name) || library?(name) || multitask?(name)
        end

        def initialize(gs)
          @gs = gs

          @interesting_tasks = Rake::Task.tasks.select { |i| interesting?(i.name) }
          create_vertices
          create_edges

          @vertices.each do |name, task|
            set_attributes(name, task)
          end

        end

        def create_vertices
          @vertices = {}
          @interesting_tasks.each do |task|
            @vertices[task.name] = task
            @gs.add_vertex(task.name)
          end
        end

        def create_edges
          @interesting_tasks.each do |task|
            from = task.name
            task.prerequisites.each do |to|
              @gs.add_edge(from, to)
            end
          end
        end

        def set_attributes(name, task)
          @gs.set_class(name, state2color(task))
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
          @gs.set_class(name, color)
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
        gs = nil
        task :init do
          gs = GraphStream.new
        end

        desc 'clear graphstream'
        task :clear => :init do
          gs.clear
        end

        desc 'update graphstream'
        task :update => :init do
          gs.set_stylesheet('node {fill-color:green;}node.dirty{fill-color:red;}node.before_prerequisites{fill-color:yellow;}node.after_prerequisites{fill-color:orange;}node.before_execute{fill-color:blue;}node.after_execute{fill-color:green;}node.ready{fill-color:yellow;}')
          require 'cxxproject/ext/rake_listener'
          require 'cxxproject/ext/rake_dirty'
          Rake::add_listener(GraphStreamSupport.new(gs))
        end
      end
    end

    optional_package(define_graphstream, nil)
  end
end

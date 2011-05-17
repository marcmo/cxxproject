begin

  require 'rubigraph'

  def apply?(name)
    name.match(/.*\.apply\Z/) != nil
  end


  module Rubigraph
    class Vertex
      alias_method :initialize_original, :initialize
      def initialize(id = nil)
        if id != nil
          @id = id
        else
          initialize_original
        end
      end
    end
  end

  class IdsAndEdges
    attr_reader :ids, :edges
    def initialize
      @ids = Hash.new
      @edges = Hash.new
    end
  end

  class V

    def self.shutdown
      File.open('id_cache', 'w') do |f|
        f.write(@@ids_and_edges.to_yaml)
      end
    end

    def self.reset
      begin
        File.delete('id_cache')
      rescue StandardError => e
        puts e
        puts 'problem deleting id_cache'
      end
      @@ids_and_edges = IdsAndEdges.new
    end

    def self.startup
      begin
        @@ids_and_edges = YAML.load_file('id_cache')
      rescue
        @@ids_and_edges = IdsAndEdges.new
      end
    end

    attr_reader :v

    def initialize(name)
      h = @@ids_and_edges.ids
      id = h[name]
      if !id
        @v = Rubigraph::Vertex.new
        @@ids_and_edges.ids()[name] = @v.id
      else
        @v = Rubigraph::Vertex.new(id)
      end
    end
    def self.create_edge(edge_and_task1, edge_and_task2)
      complete_name = "#{edge_and_task1[:task].name}->#{edge_and_task2[:task].name}"
      if @@ids_and_edges.edges.has_key?(complete_name)
        return nil
      else
        e = Rubigraph::Edge.new(edge_and_task1[:vertex].v, edge_and_task2[:vertex].v)
        @@ids_and_edges.edges[complete_name] = true
        return e
      end
    end
  end

  class UbiGraphSupport

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

      # create vertices
      interesting_tasks.each do |task|
        v = V.new(task.name)
        @vertices[task.name] = {:vertex=>v, :task=>task}
      end

      # create edges
      interesting_tasks.each do |task|
        name = task.name
        v1 = @vertices[name]
        task.prerequisites.each do |p|
          v2 = @vertices[p]
          if (v2 != nil)
            e = V.create_edge(v1, v2)
            e.width=2 if e
          end
        end
      end

      @vertices.each do |k, value|
        v = value[:vertex]
        v.v.label = k
        set_attributes(v, k)
      end

    end

    def update_colors
      @vertices.each_key do |k|
        set_attributes(v, k)
      end
    end

    def set_attributes(v, name)
      v.v.color = state2color(name)
      v.v.shape = name2shape(name)
      v.v.size = name2size(name)
    end

    def name2shape(name)
      if object?(name)
        return 'cube'
      elsif exe?(name)
        return 'sphere'
      elsif multitask?(name)
        return 'torus'
      else
        return 'octahedron'
      end
    end
    def name2size(name)
      if object?(name)
        return 0.7
      elsif exe?(name)
        return 1.2
      else
        return 1.0
      end
    end
    def state2color(name)
      t = @vertices[name][:task]
      begin
        if t.dirty?
          return '#ff0000'
        else
          return '#00ff00'
        end
      rescue StandardError => bang
        puts bang
        return '#ff00ff'
      end
    end

    def update(name, color)
      @vertices[name][:vertex].v.color = color if @vertices[name]
    end

    YELLOW = '#ffff00'
    def before_prerequisites(name)
      update(name, YELLOW)
    end

    ORANGE = '#ff7f00'
    def after_prerequisites(name)
      update(name, ORANGE)
    end

    BLUE = '#0000ff'
    def before_execute(name)
      update(name, BLUE)
    end

    GREEN = '#00ff00'
    def after_execute(name)
      update(name, GREEN)
    end
  end


  DELAY=0.01
  class StdoutRakeListener
    def before_prerequisites(name)
      sleep(DELAY)
    end

    def after_prerequisites(name)
      sleep(DELAY)
    end

    def before_execute(name)
      sleep(DELAY)
    end

    def after_execute(name)
      sleep(DELAY)
    end
  end

  LISTENER = []

  module Rake

    class MultiTask
      alias_method :invoke_prerequisites_original, :invoke_prerequisites

      def invoke_prerequisites(task_args, invocation_chain)
        LISTENER.each {|l|l.before_prerequisites(name)}
        invoke_prerequisites_original(task_args, invocation_chain)
        LISTENER.each {|l|l.after_prerequisites(name)}
        if !needed?
          LISTENER.each{|l|l.after_execute(name)}
        end
      end
    end

    class Task

      alias_method :invoke_prerequisites_original, :invoke_prerequisites

      alias_method :execute_original, :execute

      def invoke_prerequisites(task_args, invocation_chain)
        LISTENER.each {|l|l.before_prerequisites(name)}
        invoke_prerequisites_original(task_args, invocation_chain)
        LISTENER.each {|l|l.after_prerequisites(name)}
        if !needed?
          LISTENER.each{|l|l.after_execute(name)}
        end
      end

      def execute(args=nil)
        LISTENER.each {|l|l.before_execute(name)}
        execute_original(args)
        LISTENER.each {|l|l.after_execute(name)}
      end

      # return true if this or one of the prerequisites is dirty
      def dirty?
        return calc_dirty_for_prerequsites if apply?(name)

        if needed?
          return true
        end
        return calc_dirty_for_prerequsites
      end

      def calc_dirty_for_prerequsites
        res = prerequisites.find do |p|
          t = Task[p]
          if t != nil
            if t.dirty?
              true
            else
              false
            end
          else
            false
          end
        end
        return res != nil
      end
    end

  end

  namespace :rubygraph do
    task :init do
      Rubigraph.init
      V.startup
      at_exit do
        V.shutdown
      end
    end

    desc 'clear rubygraph'
    task :clear => :init do
      Rubigraph.clear
      V.reset
    end

    desc 'update rubygraph'
    task :update => :init do
      begin
        LISTENER << StdoutRakeListener.new
        LISTENER << UbiGraphSupport.new
      rescue StandardError => e
        puts e
      end
    end
  end

rescue Exception => e
  puts e
end

begin
require 'rubigraph'
  def apply?(name)
    name.match(/.*\.apply\Z/) != nil
  end


class V
  attr_reader :v
  begin
    @@id_cache = YAML.load_file('id_cache')
    puts 'cache loaded'
    puts @@id_cache
  rescue
    puts 'could not load id_cache'
    @@id_cache = Hash.new
  end

  def initialize(name)
    id = @@id_cache[name]
    if !id
      puts 'id not found ... creating new one'
      @v = Rubigraph::Vertex.new
      puts "new id -> #{@v.id}"
      @@id_cache[name] = @v.id
    else
      puts "id found #{name} => #{id}"
      @v = Rubigraph::Vertex.new(-1, id)
    end
  end
  def self.shutdown
    File.open('id_cache', 'w') do |f|
      f.write(@@id_cache.to_yaml)
    end
  end
  def self.reset
    begin
      File.delete('id_cache')
    rescue StandardError => e
      puts e
      puts 'problem deleting id_cache'
    end
    @@id_cache = Hash.new
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
      v1 = @vertices[name][:vertex]
      task.prerequisites.each do |p|
        v2 = @vertices[p]
        if (v2 != nil)
          e = Rubigraph::Edge.new(v1.v, v2[:vertex].v)
          e.width=2
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
        puts "#{name} is dirty because of itself"
        return true
      end
      return calc_dirty_for_prerequsites
    end

    def calc_dirty_for_prerequsites
      res = prerequisites.find do |p|
        t = Task[p]
        if t != nil
          if t.dirty?
            puts "#{name} is dirty because of #{p}"
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

def activate_ubigraph
  desc 'initialize rubygraph'
  task :rubygraph_init do
    Rubigraph.init
  end

  desc 'clear rubygraph'
  task :rubygraph_clear => :rubygraph_init do
    Rubigraph.clear
    V.reset
  end

  desc 'update rubygraph'
  task :rubygraph_update => :rubygraph_init do
    begin
      LISTENER << StdoutRakeListener.new
      LISTENER << UbiGraphSupport.new
    rescue
    end
  end

  at_exit do
    V.shutdown
  end
end

rescue LoadError

  def activate_ubigraph
  end

end

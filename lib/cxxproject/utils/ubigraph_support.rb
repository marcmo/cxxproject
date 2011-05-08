require 'rake'
require 'rubigraph'

class UbiGraphSupport

  def self.object?(name)
    name.match(/.*\.o\Z/) != nil
  end

  def self.exe?(name)
    name.match(/.*\.exe\Z/) != nil
  end
  def self.library?(name)
    name.match(/.*\.a\Z/) != nil
  end
  def self.interesting?(name)
    exe?(name) || object?(name) || library?(name)
  end

  def self.activate
    interesting_tasks = Rake::Task.tasks.select { |i| interesting?(i.name) }
    puts interesting_tasks.size
    vertices = {}
    Rubigraph.init
    Rubigraph.clear

    # create vertices
    interesting_tasks.each do |task|
      v = Rubigraph::Vertex.new
      set_attributes(v, task.name)
      vertices[task.name] = v
    end

    # create edges
    interesting_tasks.each do |task|
      name = task.name
      v1 = vertices[name]
      puts  "    #{task.prerequisites[0]}"
      puts "#{name} => #{task.prerequisites.join(',')}"
      task.prerequisites.each do |p|
        v2 = vertices[p]
        if (v2 != nil)
          e = Rubigraph::Edge.new(v1, v2)
          e.width=2
        end
      end
    end
    exit
  end

  def self.set_attributes(v, name)
    v.label = name
    v.color = name2color(name)
    v.size = name2size(name)
  end

  def self.name2size(name)
    if object?(name)
      return 1.0
    elsif exe?(name)
      return 3.0
    else
      return 2.0
    end
  end

  def self.name2color(name)
    if object?(name)
      return "#ff0000"
    elsif exe?(name)
      return "#00ff00"
    else
      return "#0000ff"
    end
  end
end

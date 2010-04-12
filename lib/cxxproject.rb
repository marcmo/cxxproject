require 'rubygems'
require 'yaml'
require 'rake/clean'
require 'cxxproject/utils'
require 'cxxproject/dependencies'
require 'cxxproject/compiler'
require 'cxxproject/gcccompiler'
require 'cxxproject/osxcompiler'
require 'cxxproject/configuration'

ALL_BUILDING_BLOCKS = {}

ALL = FileList.new

class BuildingBlock
  attr_accessor :name, :base
  attr_reader :config, :dependencies

  def initialize(config, name)
    @name = name
    @dependencies = []
    @config = config
    ALL_BUILDING_BLOCKS[@name] = self
  end

  def to_s
    "#{name} => #{self.class} with base: #{base}"
  end
  def set_dependencies(d)
    @dependencies = d
    self
  end
end

class LibraryBuildingBlock < BuildingBlock
  attr_reader :includes
  def initialize(config, name)
    super
    @includes = ['.']
  end
  def set_includes(i)
    @includes = i
  end
end

class SourceBuildingBlock < LibraryBuildingBlock
  attr_reader :sources

  def initialize(config, name)
    super
    @sources = []
    @dependencies = []
  end
  def to_s
    s = "#{super} sources: "
    @sources.each_with_index do |source, i|
      if i != 0
        s = s + ', '
      end
      s = s + source
    end
    s
  end
  def set_sources(s)
    @sources = s
    self
  end
end

class SourceLibrary < SourceBuildingBlock
  attr_reader :defines
  def initialize(config, name)
    super
    @defines = []
  end
end

class Exe < SourceBuildingBlock
  def initialize(config, name)
    super
  end
end

class BinaryLibrary < LibraryBuildingBlock
  def initialize(config, name)
    super
    @includes = ['']
  end
end

def build_source_lib(lib,compiler)
  objects = lib.sources.map do |s|
    compiler.create_object_file(lib, File.basename(s))
  end
  compiler.create_source_lib(lib, objects)
end

def build_exe(exe,compiler)
  objects = exe.sources.map do |s|
    compiler.create_object_file(exe, File.basename(s))
  end
  compiler.create_exe(exe, objects)
end

class CxxProject2Rake
  attr_accessor :compiler
  def initialize(projects,compiler)
    @compiler = compiler
    register_projects(projects)

    define_project_info_task

    convert_to_rake()
  end

  def define_project_info_task
    desc "shows your defined projects"
    task :project_info do
      ALL_BUILDING_BLOCKS.each_value do |bb|
        puts bb
      end
    end
  end

  def register_projects(projects)
    projects.each do |project_file|
      loadContext = Class.new
      loadContext.module_eval(File.read(project_file))
      c = loadContext.new
      raise "no 'define_project' defined in project.rb" unless c.respond_to?(:define_project)
      cd(File.dirname(project_file),:verbose => false) do | base_dir |
        configuration = Configuration.new(File.absolute_path(base_dir))
        project = c.define_project(configuration)
        project.base = base_dir
        project.to_s
      end
    end
  end

  def convert_to_rake
    ALL_BUILDING_BLOCKS.values.each do |building_block|
      if (building_block.instance_of?(SourceLibrary)) then
        build_source_lib(building_block,@compiler)
      elsif (building_block.instance_of?(Exe)) then
        build_exe(building_block,@compiler)
      elsif (building_block.instance_of?(BinaryLibrary)) then
      else
        raise 'unknown building_block'
      end
    end
    task :default => ALL.to_a do
    end
  end
end

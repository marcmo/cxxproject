require 'rubygems'
require 'rake/clean'
require 'cxxproject/utils'
require 'cxxproject/dependencies'
require 'cxxproject/compiler'
require 'cxxproject/gcccompiler'
require 'cxxproject/osxcompiler'

ALL_BUILDING_BLOCKS = {}

ALL = FileList.new

class BuildingBlock
  attr_accessor :name, :base, :dependencies

  def initialize(name)
    @name = name
    @dependencies = []
    ALL_BUILDING_BLOCKS[@name] = self
  end

  def to_s
    "#{name} => #{self.class} with base: #{base}"
  end
end

class LibraryBuildingBlock < BuildingBlock
  attr_accessor :includes
  def initialize(name)
    super
    @includes = ['.']
  end
end

class SourceBuildingBlock < LibraryBuildingBlock
  attr_accessor :sources

  def initialize(name)
    super(name)
    @sources = []
    @dependencies = []
  end
end

class SourceLibrary < SourceBuildingBlock
  attr_accessor :defines
  def initialize(name)
    super(name)
    @defines = []
  end
end

class Exe < SourceBuildingBlock
  def initialize(name)
    super(name)
  end
end

class BinaryLibrary < LibraryBuildingBlock
  def initialize(name)
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

    desc "shows your defined projects"
    task :project_info do
      ALL_BUILDING_BLOCKS.each_value do |bb|
        puts bb
      end
    end

    convert_to_rake()
  end

  def register_projects(projects)
    projects.each do |project_file|
      loadContext = Class.new
      loadContext.module_eval(File.read(project_file))
      c = loadContext.new
      raise "no 'define_project' defined in project.rb" unless c.respond_to?(:define_project)
      FileUtils.cd(File.dirname(project_file),:verbose => false) do | base_dir |
        project = c.define_project
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

require 'pp'

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

# class which converts cxx-projects to rake-tasks
# can be used in a rakefile like:
# require 'cxxproject'
# CxxProject2Rake.new(Dir.glob('**/project.rb'), OsxCompiler.new('build'))
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
        pp bb
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
        configuration = Configuration.new(File.expand_path(base_dir))
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

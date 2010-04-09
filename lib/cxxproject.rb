require 'rake/clean'
require 'cxxproject/dependencies'

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
    inspect
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

class OsxCompiler
  def initialize(output_path)
    @output_path = output_path
  end

  def register(name)
    CLEAN.include(name)
    ALL.include(name)
  end

  def transitive_includes(lib)
    res = Dependencies.transitive_dependencies([lib.name]).map do |i|
      if (i.instance_of?(BinaryLibrary))
        i.includes
      else
        i.includes.map { |include| File.join(i.base, include) }
      end
    end
    return res.flatten.delete_if{|i|i.size == 0}
  end

  def transitive_libs(from)
    res = Dependencies.transitive_dependencies([from.name]).delete_if{|i|i.instance_of?(Exe)}.map do |i|
      if (i.instance_of?(BinaryLibrary))
        "-l#{i.name}"
      else
        "osx/lib#{i.name}.a"
      end
    end
    return res
  end

  def create_object_file(lib, relative_source)
    source = File.join(lib.base, relative_source)
    out = File.join(@output_path, "#{source}.o")
    outputdir = File.dirname(out)
    directory outputdir
    register(out)
    desc "compiling #{source}"
    res = file out => [source, outputdir] do |t|
      includes = transitive_includes(lib)
      include_string = includes.inject('') { | res, i | "#{res} -I#{i} " }
      sh "g++ -c #{source} #{include_string} -o #{t.name}"
    end
    return res
  end

  def static_lib_path(name)
    libname = "lib#{name}.a"
    fullpath = File.join(@output_path, libname)
    return fullpath
  end

  def create_source_lib(lib, objects)
    fullpath = static_lib_path(lib.name)
    command = objects.inject("ar -r #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    register(fullpath)
    deps = objects.dup
    deps += lib.dependencies.map {|dep|get_path_for_lib(dep)}
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      sh command
    end
    return res
  end

  def get_path_for_lib(l)
    lib = ALL_BUILDING_BLOCKS[l]
    if !lib
      raise "could not find buildingblock with name '#{l}'"
    end
    if (lib.instance_of?(BinaryLibrary))
      "/opt/local/lib/lib#{lib.name}.a"
    else
      static_lib_path(lib.name)
    end
  end

  def create_exe(exe, objects)
    exename = "#{exe.name}.exe"
    fullpath = File.join(@output_path, exename)
    command = objects.inject("g++ -o #{fullpath}") do |command, o|
      "#{command} #{o}"
    end

    dep_paths = exe.dependencies.map {|dep|get_path_for_lib(dep)}
    register(fullpath)
    deps = objects.dup
    deps += dep_paths
    desc "link exe #{exe.name}"
    res = file fullpath => deps do
      libs = transitive_libs(exe)
      command = libs.inject(command) { |command, l| "#{command} #{l}" }
      sh command
    end
    return res
  end
end


def build_source_lib(lib)
  objects = lib.sources.map do |s|
    Compiler.create_object_file(lib, File.basename(s))
  end
  Compiler.create_source_lib(lib, objects)
end

def build_exe(exe)
  objects = exe.sources.map do |s|
    Compiler.create_object_file(exe, File.basename(s))
  end
  Compiler.create_exe(exe, objects)
end

class CxxProject2Rake

  def initialize(projects)
    register_projects(projects)
    convert_to_rake
  end

  def register_projects(projects)
    projects.each do |project_file|
      loadContext = Class.new
      loadContext.module_eval(File.read(project_file))
      c = loadContext.new
      raise "no 'define_project' defined in project.rb" unless c.respond_to?(:define_project)
      cd File.dirname(project_file) do | base_dir |
        project = c.define_project
        ALL_BUILDING_BLOCKS[project.name] = project
        project.base = base_dir
        project.to_s
      end
    end
  end
  def convert_to_rake
    ALL_BUILDING_BLOCKS.values.each do |building_block|
      if (building_block.instance_of?(SourceLibrary)) then
        build_source_lib(building_block)
      elsif (building_block.instance_of?(Exe)) then
        build_exe(building_block)
      elsif (building_block.instance_of?(BinaryLibrary)) then
      else
        raise 'unknown building_block'
      end
    end
    task :default => ALL.to_a do
    end
  end
end

require 'rake/clean'

ALL = Rake::FileList.new

ALL_BUILDING_BLOCKS = {}
class BuildingBlock
  attr_accessor :name, :base, :dependencies, :libs
  def initialize
    super
    @dependencies = []
    @libs = []
  end
  def to_s
    inspect
  end
end

class SourceBuildingBlock < BuildingBlock
  attr_accessor :sources, :includes
  def initialize
    super
    @sources = []
    @includes = ['.']
    @dependencies = []
  end
end

class SourceLibrary < SourceBuildingBlock
  attr_accessor :defines
  def initialize
    super
    @defines = []
  end
end

class Exe < SourceBuildingBlock
  def initialize
    super
  end
end

class OsxCompiler
  def initialize(output_path)
    @output_path = output_path
  end

  def include(name)
    CLEAN.include(name)
    ALL.include(name)
  end

  def transitive_dependencies(building_block)
    if !building_block
      raise "transitive dependencies ... building block must not be nil"
    end
    res = [building_block]
    building_block.dependencies.each do |d|
      h = ALL_BUILDING_BLOCKS[d]
      if !h
        raise "dependency not found #{d}"
      end
      new_one = transitive_dependencies(h)
      res += new_one
    end
    return res
  end

  def transitive_includes(lib)
    res = transitive_dependencies(lib).map do |i|
      i.includes.map { |include| File.join(i.base, include) }
    end
    return res.flatten
  end
  def transitive_libs(from)
    
    res = transitive_dependencies(from).delete_if{|i|i.instance_of?(Exe)}.map do |i|
      "osx/lib#{i.name}.a"
    end
    return res
  end

  def create_object_file(lib, relative_source)
    source = File.join(lib.base, relative_source)
    out = File.join(@output_path, "#{source}.o")
    outputdir = File.dirname(out)
    directory outputdir
    include(out)
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
    include(fullpath)
    deps = objects.dup
    deps += lib.dependencies.map {|dep|static_lib_path(dep)}
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      sh command
    end
    return res
  end

  def create_exe(exe, objects)
    exename = "#{exe.name}.exe"
    fullpath = File.join(@output_path, exename)
    command = objects.inject("g++ -o #{fullpath}") do |command, o|
      "#{command} #{o}"
    end

    dep_paths = exe.dependencies.map {|dep|static_lib_path(dep)}
    command = dep_paths.inject(command) do |command, l|
      "#{command} #{l}"
    end
    include(fullpath)
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

def compiler
  OsxCompiler.new('osx')
end

def build_source_lib(lib)
  objects = lib.sources.map do |s|
    compiler.create_object_file(lib, s)
  end
  compiler.create_source_lib(lib, objects)
end

def build_exe(exe)
  objects = exe.sources.map do |s|
    compiler.create_object_file(exe, s)
  end
  compiler.create_exe(exe, objects)
end

all_building_blocks = {}
projects = Dir.glob('**/project.rb')
projects.each do |p|
  require p
  building_block = define_project
  building_block.base = File.dirname(p)
  ALL_BUILDING_BLOCKS[building_block.name] = building_block
  if (building_block.instance_of?(SourceLibrary)) then
    build_source_lib(building_block)
  elsif (building_block.instance_of?(Exe)) then
    build_exe(building_block)
  else
    raise 'unknown building_block'
  end
end

task :default => ALL.to_a do
end

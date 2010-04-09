require 'rake/clean'
require 'cxxproject'

class OsxCompiler
  def initialize(output_path)
    @output_path = output_path
  end

  def include(name)
    CLEAN.include(name)
#    ALL.include(name)
  end

  def transitive_includes(lib)
    res = Dependencies.transitive_dependencies([lib.name]).map do |i|
      i.includes.map { |include| File.join(i.base, include) }
    end
    return res.flatten
  end
  def transitive_libs(from)
    res = Dependencies.transitive_dependencies([from.name]).delete_if{|i|i.instance_of?(Exe)}.map do |i|
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

Compiler = OsxCompiler.new('osx')

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

all_building_blocks = {}
projects = Dir.glob('**/project.rb')
projects.each do |p|
  loadContext = Class.new
  loadContext.module_eval(File.read(p))
  c = loadContext.new
  raise "no 'define_project' defined in project.rb" unless c.respond_to?(:define_project)
  base_dir = File.dirname(p)
  cd base_dir do
    building_block = c.define_project 
    building_block.base = base_dir
    ALL_BUILDING_BLOCKS[building_block.name] = building_block
    if (building_block.instance_of?(SourceLibrary)) then
      build_source_lib(building_block)
    elsif (building_block.instance_of?(Exe)) then
      build_exe(building_block)
    else
      raise 'unknown building_block'
    end
  end
end

task :default do
end

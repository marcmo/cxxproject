require 'rake/clean'

ALL = Rake::FileList.new

class SourceLibrary
  attr_accessor :sources, :includes, :defines, :name
end

class Exe
  attr_accessor :libs, :name, :sources
end

class OsxCompiler
  def initialize(output_path)
    @output_path = output_path
  end

  def include(name)
    CLEAN.include(name)
    ALL.include(name)
  end

  def create_object_file(output, source)
    out = File.join(@output_path, "#{source}.o")
    outputdir = File.dirname(out)
    directory outputdir
    include(out)
    desc "compiling #{source}"
    res = file out => [source, outputdir] do |t|
      sh "g++ -c #{source} -o #{t.name}"
    end
    return res
  end

  def static_lib_path(name)
    libname = "lib#{name}.a"
    fullpath = File.join(@output_path, libname)
    return fullpath
  end

  def create_source_lib(name, objects)
    fullpath = static_lib_path(name)
    command = objects.inject("ar -r #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    include(fullpath)
    desc "link lib #{name}"
    res = file fullpath => objects do
      sh command
    end
    return res
  end

  def create_exe(name, objects, libs)
    exename = "#{name}.exe"
    fullpath = File.join(@output_path, exename)
    command = objects.inject("g++ -o #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    lib_paths = libs.map {|lib|static_lib_path(lib)}
    command = lib_paths.inject(command) do |command, l|
      "#{command} #{l}"
    end
    include(fullpath)
    deps = objects.dup
    deps += lib_paths
    desc "link exe #{name}"
    res = file fullpath => deps do
      sh command
    end
    return res
  end
end

def compiler
  OsxCompiler.new('osx')
end

def build_source_lib(base, lib)
  objects = lib.sources.map do |s|
    compiler.create_object_file(lib.name, File.join(base, s))
  end
  compiler.create_source_lib(lib.name, objects)
end

def build_exe(base, exe)
  objects = exe.sources.map do |s|
    compiler.create_object_file(exe.name, File.join(base, s))
  end
  compiler.create_exe(exe.name, objects, exe.libs)
end

projects = Dir.glob('**/project.rb')
projects.each do |p|
  require p
  help = define_project
  if (help.instance_of?(SourceLibrary)) then
    build_source_lib(File.dirname(p), help)
  elsif (help.instance_of?(Exe)) then
    build_exe(File.dirname(p), help)
  end
end

task :default => ALL.to_a do
end

ALL.each do |task|
  puts Rake::Task[task].inspect
end

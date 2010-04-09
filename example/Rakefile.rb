require 'rake/clean'
require 'cxxproject'

include OS

if OS.mac?
  COMPILER = OsxCompiler.new('osx')
elsif OS.unix?
  COMPILER = GccCompiler.new('gcc')
end

def build_source_lib(lib)
  objects = lib.sources.map do |s|
    COMPILER.create_object_file(lib, File.basename(s))
  end
  COMPILER.create_source_lib(lib, objects)
end

def build_exe(exe)
  objects = exe.sources.map do |s|
    COMPILER.create_object_file(exe, File.basename(s))
  end
  COMPILER.create_exe(exe, objects)
end

all_building_blocks = {}
projects = Dir.glob('**/project.rb')
projects.each do |p|
  loadContext = Class.new
  loadContext.module_eval(File.read(p))
  c = loadContext.new
  raise "no 'define_project' defined in project.rb" unless c.respond_to?(:define_project)
  base_dir = File.dirname(p)
  building_block = nil
  cd base_dir do
    building_block = c.define_project 
  end
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

task :default do
end

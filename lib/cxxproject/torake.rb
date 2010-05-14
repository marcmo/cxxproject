require 'pp'
require 'pathname'

# class which converts cxx-projects to rake-tasks
# can be used in a rakefile like:
# require 'cxxproject'
# CxxProject2Rake.new(Dir.glob('**/project.rb'), OsxCompiler.new('build'))
class CxxProject2Rake

  attr_accessor :compiler, :base

  def initialize(projects, compiler, base='./')
    @compiler = compiler
    @base = base
    projects = projects.map { |p| p.remove_from_start(base) }
    projects = projects.map { |p| p.remove_from_start(base) }
    register_projects(projects)
    define_project_info_task()
    convert_to_rake()
  end

  def define_project_info_task
    desc "shows your defined projects"
    task :project_info do
      p "ProjectBase: #{@base}"
      ALL_BUILDING_BLOCKS.each_value do |bb|
        pp bb
      end
    end
  end

  def register_projects(projects)
    cd(@base,:verbose => false) do |b|
      projects.each do |project_file|
        # puts "register project #{project_file}" 
        dirname = File.dirname(project_file)
        cd(dirname,:verbose => false) do | base_dir |
          loadContext = EvalContext.new
          loadContext.eval_project(File.read(File.basename(project_file)))
          raise "project config invalid for #{project_file}" unless loadContext.name
          project = loadContext.myblock.call()
          project.base = File.join(@base, base_dir)
          project.to_s
        end
      end
    end
  end

  def build_source_lib(lib,compiler)
    objects = lib.sources.map do |s|
      compiler.create_object_file(lib, s, @base)
    end
    compiler.create_source_lib(lib, objects)
  end

  def build_exe(exe,compiler)
    objects = exe.sources.map do |s|
      compiler.create_object_file(exe, s, @base)
    end
    compiler.create_exe(exe, objects)
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

class EvalContext

  attr_accessor :name, :myblock

  def cxx_configuration(name, &block)
    @myblock = block
    @name = name
  end

  def eval_project(project_text)
    instance_eval(project_text)
  end
  
  def configuration(*args, &block)
    name = args[0]
    raise "no name given" unless name.is_a?(String) && !name.strip.empty?
    instance_eval(&block)
  end

  def check_hash(hash,allowed)
    hash.keys.map {|k| raise "#{k} is not a valid specifier!" unless allowed.include?(k) }
  end

  def exe(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes,:dependencies]
    exe = Exe.new(name)
    exe.set_sources(hash[:sources]) if hash.has_key?(:sources)
    exe.set_includes(hash[:includes]) if hash.has_key?(:includes)
    exe.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)
    exe
  end

  def source_lib(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes,:dependencies]
    raise ":sources need to be defined" unless hash.has_key?(:sources)
    exe = SourceLibrary.new(name).set_sources(hash[:sources])
    exe.set_includes(hash[:includes]) if hash.has_key?(:includes)
    exe.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)
    exe
  end

end

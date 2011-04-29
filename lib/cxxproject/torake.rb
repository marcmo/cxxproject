require 'logger'
require 'pp'
require 'pathname'
require 'cxxproject/rake_ext'

# class which converts cxx-projects to rake-tasks
# can be used in a rakefile like:
# require 'cxxproject'
# CxxProject2Rake.new(Dir.glob('**/project.rb'), OsxCompiler.new('build'))
class CxxProject2Rake

  attr_accessor :compiler, :base

  def initialize(projects, compiler, base='./', logLevel=Logger::ERROR)
    @log = Logger.new(STDOUT)
    @log.level = logLevel
    @log.debug "starting..."
    @compiler = compiler
    @compiler.set_loglevel(logLevel);
    @base = base
    projects = projects.map { |p| p.remove_from_start(base) }
    @log.debug "projects: #{projects}"
    register_projects(projects)
    define_project_info_task()
    convert_to_rake_tasks(projects)
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
        @log.debug "register project #{project_file}" 
        dirname = File.dirname(project_file)
        @log.debug "dirname for project was: #{dirname}"
        cd(dirname,:verbose => false) do | base_dir |
          @log.debug "current dir: #{`pwd`}"
          loadContext = EvalContext.new
          loadContext.eval_project(File.read(File.basename(project_file)))
          raise "project config invalid for #{project_file}" unless loadContext.name
          project = loadContext.myblock.call()
          project.base = File.join(@base, base_dir)
        end
      end
    end
  end

private

  def convert_to_rake_tasks(projects)
    ALL_BUILDING_BLOCKS.values.each do |building_block|
      if (building_block.instance_of?(SourceLibrary)) then
        build_source_lib_task(building_block,@compiler)
      elsif (building_block.instance_of?(Exe)) then
        build_exe_task(building_block,@compiler,projects)
      elsif (building_block.instance_of?(BinaryLibrary)) then
      else
        raise 'unknown building_block'
      end
    end
    task :default => ALL.to_a do
    end
  end

  def build_source_lib_task(lib,compiler)
    @log.debug "building source lib"
    objects = lib.sources.map do |s|
      compiler.create_object_file_task(lib, s, @base)
    end
    t = multitask "multitask_#{lib}" => objects
    compiler.create_source_lib(lib, t)
  end

  def build_exe_task(exe,compiler,projects)
    objects = exe.sources.map do |s|
      compiler.create_object_file_task(exe, s, @base)
    end
    t = multitask "multitask_#{exe}"  => objects
    compiler.create_exe_task(exe, t,projects)
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

require 'logger'
require 'pp'
require 'pathname'
require 'cxxproject/rake_ext'
require 'cxxproject/toolchain/gcc'
require 'cxxproject/task_maker'

# class which converts cxx-projects to rake-tasks
# can be used in a rakefile like:
# require 'cxxproject'
# CxxProject2Rake.new(Dir.glob('**/project.rb'), OsxCompiler.new('build'))
class CxxProject2Rake

  attr_accessor :base
  attr_reader :root_task

  def initialize(projects, compiler, base='.', logLevel=Logger::ERROR, norun=false)
    puts "CxxProject2Rake, in constructor"
    @log = Logger.new(STDOUT)
    @log.level = logLevel
    @log.debug "starting..."
    @base = base
    instantiate_tasks(projects, compiler, base) unless norun
  end

  def instantiate_tasks(projects, compiler, base='./')
    project_configs = projects.map { |p| p.remove_from_start(base) }
    @log.debug "project_configs: #{project_configs}"
    register_projects(project_configs)
    define_project_info_task()
    gcc = Cxxproject::Toolchain::GCCChain
    task_maker = TaskMaker.new(compiler.output_path, ALL_BUILDING_BLOCKS, gcc)
    task_maker.set_loglevel(@log.level);
    tasks = []
    ALL_BUILDING_BLOCKS.each do |name,block|
      puts "creating task for block: #{block}"
      t = task_maker.create_tasks_for_building_blocks(block, project_configs, base)
      if (t != nil)
        tasks << { :task => t, :name => name }
      end
    end
    tasks
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
          project.to_s
        end
      end
    end
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

  def read_project_config(project_file)
    building_block = nil
    cd(@base,:verbose => false) do |b|
      @log.debug "register project #{project_file}" 
      dirname = File.dirname(project_file)
      @log.debug "dirname for project was: #{dirname}"
      cd(dirname,:verbose => false) do | base_dir |
        @log.debug "current dir: #{`pwd`}"
        loadContext = EvalContext.new
        loadContext.eval_project(File.read(File.basename(project_file)))
        raise "project config invalid for #{project_file}" unless loadContext.name
        building_block = loadContext.myblock.call()
        building_block.base = File.join(@base, base_dir)
      end
    end
    puts "building_block was: " + building_block.inspect
    building_block
  end

private

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
    bblock = Exe.new(name)
    bblock.set_sources(hash[:sources]) if hash.has_key?(:sources)
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    bblock.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)
    bblock
  end

  def source_lib(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes,:dependencies]
    raise ":sources need to be defined" unless hash.has_key?(:sources)
    bblock = SourceLibrary.new(name).set_sources(hash[:sources])
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    bblock.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)
    bblock
  end

end

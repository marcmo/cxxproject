require 'logger'
require 'pp'
require 'pathname'
require 'cxxproject/extensions/rake_ext'
require 'cxxproject/toolchain/gcc'
require 'cxxproject/task_maker'

# class which converts cxx-projects to rake-tasks
# can be used in a rakefile like:
# require 'cxxproject'
# CxxProject2Rake.new(Dir.glob('**/project.rb'), OsxCompiler.new('build'))
class CxxProject2Rake

  attr_accessor :base
  attr_reader :root_task

  def print_pres(tt)
    dirty_count = 0
    inner = lambda do |t,level|
      s = ""
      if t.needed? && tt.instance_of?(FileTask) then
        level.times { s = s + "xxx" }
        puts "#{s} #{level}.level: #{task2string(t)}, deps:#{t.prerequisites}"
      else
        level.times { s = s + "---" }
        # puts "#{s} #{level}.level: #{task2string(t)}"
      end
      dirty_count += 1 unless !(t.instance_of?(FileTask) && t.needed?)
      prerequisites = prerequisites_if_any(t)
      prerequisites.each do |p|
        x = t.application[p, t.scope]
        inner.call(x,level+1)
      end
    end
    inner.call(tt,0)
    dirty_count
  end
  def prerequisites_if_any(t)
    if t.respond_to?('prerequisites')
      t.prerequisites
    else
      []
    end
  end
  def task2string(t)
    if t.instance_of?(FileTask)
      t.name
    else
      File.basename(t.name)
    end
  end
  def initialize(projects, build_dir, toolchain, base='./', logLevel=Logger::ERROR, norun=false)
    @log = Logger.new(STDOUT)
    @log.level = logLevel
    # @log.level = Logger::DEBUG
    @log.debug "starting..."
    @base = base
    instantiate_tasks(projects, build_dir, toolchain, base) unless norun
  end

  def instantiate_tasks(projects, build_dir, toolchain, base='./')
    project_configs = projects.map { |p| p.remove_from_start(base) }
    @log.debug "project_configs: #{project_configs}"
    register_projects(project_configs)
    define_project_info_task()
    @gcc = toolchain # Cxxproject::Toolchain::GCCChain
    task_maker = TaskMaker.new(@log)
    task_maker.set_loglevel(@log.level);
    tasks = []

    #todo: sort ALL_BUILDING_BLOCKS (circular deps)

    ALL_BUILDING_BLOCKS.each do |name,block|
      block.set_tcs(@gcc)
      block.set_output_dir(Dir.pwd + "/" + build_dir)
      # block.set_config_files(project_configs)
      block.set_config_files([])
      block.complete_init()
    end

    ALL_BUILDING_BLOCKS.each do |name,block|
      @log.debug "creating task for block: #{block.name}/taskname: #{block.get_task_name} (#{block})"
      t = task_maker.create_tasks_for_building_block(block)
      if (t != nil)
        tasks << { :task => t, :name => name }
      end
    end
    # tasks.each { |t| print_pres(t[:task]) }
    tasks
  end

  def register_projects(projects)
    cd(@base,:verbose => false) do |b|
      projects.each do |project_file|
        @log.debug "register project #{project_file}"
        dirname = File.dirname(project_file)
        @log.debug "dirname for project was: #{dirname}"
        cd(dirname,:verbose => false) do | base_dir |
          @log.debug "current dir: #{`pwd`}, #{base_dir}"
          loadContext = EvalContext.new
          loadContext.eval_project(File.read(File.basename(project_file)))
          raise "project config invalid for #{project_file}" unless loadContext.name

          project = loadContext.myblock.call()
          if project.sources.instance_of?(Rake::FileList)
            project.set_sources(project.sources.to_a)
          end
          project.set_project_dir(Dir.pwd)
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
        building_block.set_project_dir(File.join(@base, base_dir))
      end
    end
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
    bblock = Executable.new(name)
    bblock.set_sources(hash[:sources]) if hash.has_key?(:sources)
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    bblock.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)

    if OS.linux?
      bblock.set_lib_searchpaths(["/usr/local/lib","/usr/lib"])
    else
      bblock.set_lib_searchpaths(["C:/tool/cygwin/lib"])
    end
    bblock
  end

  def source_lib(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes,:dependencies]
    raise ":sources need to be defined" unless hash.has_key?(:sources)
    bblock = SourceLibrary.new(name)
    bblock.set_sources(hash[:sources])
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    bblock.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)
    bblock
  end

  def compile(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes]
    bblock = SingleSource.new(name)
    bblock.set_sources(hash[:sources]) if hash.has_key?(:sources)
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    bblock
  end

end

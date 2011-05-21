require 'logger'
require 'pp'
require 'pathname'
require 'cxxproject/extensions/rake_ext'
require 'cxxproject/toolchain/gcc'
require 'cxxproject/toolchain/gcc_osx'
require 'cxxproject/task_maker'

class CxxProject2Rake

  attr_accessor :base, :all_tasks

  def initialize(projects, build_dir, toolchain, base='.', logLevel=Logger::ERROR)
    pwd = `pwd`
    @log = Logger.new(STDOUT)
    @log.formatter = proc { |severity, datetime, progname, msg|
      "#{severity}: #{msg}\n"
    }

    @log.level = logLevel
    @log.debug "starting..."
    @base = base
    @all_tasks = instantiate_tasks(projects, build_dir, toolchain, base)
  end

  def instantiate_tasks(project_configs, build_dir, toolchain, base='.')
    FileUtils.cd base do
      project_configs.each do |p|
        abort "project config #{p} cannot be found!" unless File.exists?(p)
      end
    end
    @log.debug "project_configs: #{project_configs}"
    register_projects(project_configs)
    define_project_info_task()
    @gcc = toolchain
    task_maker = TaskMaker.new(@log)
    task_maker.set_loglevel(@log.level);
    tasks = []

    #todo: sort ALL_BUILDING_BLOCKS (circular deps)

    ALL_BUILDING_BLOCKS.each do |name,block|
      block.set_tcs(@gcc) unless block.has_tcs?
      block.set_output_dir(Dir.pwd + "/" + build_dir)
      rel_projects = project_configs.collect { |p| File.join(base,p) }
      block.set_config_files(rel_projects)
      block.complete_init()
    end

    ALL_BUILDING_BLOCKS.each do |name,block|
      @log.debug "creating task for block: #{block.name}/taskname: #{block.get_task_name} (#{block})"
      t = task_maker.create_tasks_for_building_block(block)
      if (t != nil)
        tasks << { :task => t, :name => name }
      end
    end
    tasks
  end

  def register_projects(projects)
    FileUtils.cd(@base,:verbose => false) do |b|
      projects.each do |project_file|
        @log.debug "register project #{project_file}"
        dirname = File.dirname(project_file)
        @log.debug "dirname for project was: #{dirname}"
        FileUtils.cd(dirname,:verbose => false) do | base_dir |
          @log.debug "current dir: #{`pwd`}, #{base_dir}"
          loadContext = EvalContext.new
          loadContext.eval_project(File.read(File.basename(project_file)))
          loadContext.myblock.call()
          loadContext.all_blocks.each do |p|
            p.set_project_dir(Dir.pwd)
            if p.sources.instance_of?(Rake::FileList)
              p.set_sources(p.sources.to_a)
            end
          end
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

end

class EvalContext

  attr_accessor :myblock, :all_blocks

  def cxx_configuration(&block)
    @myblock = block
    @all_blocks = []
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
    elsif OS.mac?
      bblock.set_lib_searchpaths(['/usr/lib'])
      puts "WARNING ... please use correct lib_searchpath in to_rake for mac"
    else
      bblock.set_lib_searchpaths(["C:/tool/cygwin/lib"])
    end
    all_blocks << bblock
  end

  def source_lib(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes,:dependencies,:toolchain]
    raise ":sources need to be defined" unless hash.has_key?(:sources)
    bblock = SourceLibrary.new(name)
    bblock.set_sources(hash[:sources])
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    bblock.set_tcs(hash[:toolchain]) if hash.has_key?(:toolchain)
    bblock.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)
    all_blocks << bblock
  end

  def compile(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources,:includes]
    bblock = SingleSource.new(name)
    bblock.set_sources(hash[:sources]) if hash.has_key?(:sources)
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    all_blocks << bblock
  end

end

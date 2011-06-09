require 'logger'
require 'pp'
require 'pathname'
require 'cxxproject/extensions/rake_ext'
require 'cxxproject/buildingblocks/module'
require 'cxxproject/buildingblocks/makefile'
require 'cxxproject/buildingblocks/executable'
require 'cxxproject/buildingblocks/source_library'
require 'cxxproject/buildingblocks/single_source'
require 'cxxproject/buildingblocks/binary_library'
require 'cxxproject/buildingblocks/custom_building_block'
require 'cxxproject/buildingblocks/command_line'
require 'cxxproject/toolchain/colorizing_formatter'

class CxxProject2Rake
  begin
    include Rake::DSL
  rescue
    puts 'please update your rake installation'
  end

  attr_accessor :base, :all_tasks

  def initialize(projects, build_dir, toolchain, base='.')
    pwd = `pwd`
    @log = Logger.new(STDOUT)
    @log.formatter = proc { |severity, datetime, progname, msg|
      "#{severity}: #{msg}\n"
    }
    # Logger loglevels: fatal, error, warn, info, debug
    # Rake --verbose -> info
    # Rake --trace -> debug
    @log.level = Logger::ERROR
    @log.level = Logger::INFO if RakeFileUtils.verbose == true
    BuildingBlock.verbose = true if RakeFileUtils.verbose == true
    @log.level = Logger::DEBUG if Rake::application.options.trace
    @log.debug "initializing for build_dir: \"#{build_dir}\", base: \"#{base}\""
    @base = base
    @all_tasks = instantiate_tasks(projects, build_dir, toolchain, base)

    create_generic_tasks
    handle_console_colorization
    handle_multitask
  end
  def handle_multitask
    desc 'set parallelization of multitask'
    task :multitask, :nr_of_threads do |t, args|
      puts args
      arg = args[:nr_of_threads]
      if arg
        Rake::MultiTask.set_max_parallel_tasks(arg.to_i)
      end
    end
  end
  def handle_console_colorization
    # default is on
    Cxxproject::ColorizingFormatter.enabled = true
    desc 'Toggle colorization of console output (use true|t|yes|y|1 for true ... everything else is false)'
    task :toggle_colorize, :on_off do |t, args|
      arg = args[:on_off] || 'false'
      on_off = arg.match(/(true|t|yes|y|1)$/) != nil
      puts on_off
      Cxxproject::ColorizingFormatter.enabled = on_off
    end
  end

  def create_generic_tasks
    [:lib, :exe, :run, nil].each { |i| create_filter_task_with_namespace(i) }
  end

  def create_filter_task_with_namespace(basename)
    if basename
      desc "invoke #{basename} with filter"
      namespace basename do
        create_filter_task("#{basename}:")
      end
    else
      desc 'invoke with filter'
      create_filter_task('')
    end
  end

  def create_filter_task(basename)
    task :filter, :filter do |t, args|
      filter = ".*"
      if args[:filter]
        filter = "#{args[:filter]}"
      end
      filter = Regexp.new("#{basename}#{filter}")
      Rake::Task.tasks.each do |to_check|
        name = to_check.name
        if ("#{basename}:filter" != name)
          match = filter.match(name)
          if match
            to_check.invoke
          end
        end
      end
    end
  end

  def instantiate_tasks(project_configs, build_dir, toolchain, base='.')
    cd(base, :verbose => false) do
      project_configs.each do |p|
        abort "project config #{p} cannot be found!" unless File.exists?(p)
      end
    end
    @log.debug "project_configs:"
    project_configs.each { |c| @log.debug " *  #{c}" }
    register_projects(project_configs)
    define_project_info_task()

    tasks = []

    #todo: sort ALL_BUILDING_BLOCKS (circular deps)

    ALL_BUILDING_BLOCKS.each do |name,block|
      block.set_tcs(toolchain) unless block.has_tcs?
      block.set_output_dir(Dir.pwd + "/" + build_dir)
      rel_projects = project_configs.collect { |p| File.join(base,p) }
      block.set_config_files(rel_projects)
      block.complete_init()
    end

    ALL_BUILDING_BLOCKS.each do |name,block|
      @log.debug "creating task for block: #{block.name}/taskname: #{block.get_task_name} (#{block})"
      t = block.convert_to_rake()
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
          pwd = `pwd`
          @log.debug "register project #{project_file} from within directory: #{pwd.chomp}"
          eval_file(b, File.basename(project_file))
        end
      end
    end
  end
  def eval_file(b, project_file)
    loadContext = EvalContext.new
    begin
      loadContext.eval_project(File.read(File.basename(project_file)))
    rescue Exception => e
      puts "problems with #{File.join(b, project_file)}"
      raise e
    end
    loadContext.myblock.call()
    loadContext.all_blocks.each do |p|
      p.set_project_dir(Dir.pwd)
      if p.respond_to?(:sources) && p.sources.instance_of?(Rake::FileList)
        p.set_sources(p.sources.to_a)
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
    check_hash hash,[:sources,:includes,:dependencies,:libpath]
    bblock = Executable.new(name)
    bblock.set_sources(hash[:sources]) if hash.has_key?(:sources)
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    bblock.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)
    if hash.has_key?(:libpath)
      bblock.set_lib_searchpaths(hash[:libpath])
    elsif
      if OS.linux? || OS.mac?
        bblock.set_lib_searchpaths(["/usr/local/lib","/usr/lib"])
      elsif OS.windows?
        bblock.set_lib_searchpaths(["C:/tool/cygwin/lib"])
      end
    end
    all_blocks << bblock
  end

  def source_lib(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:sources, :includes, :dependencies, :toolchain, :file_dependencies]
    raise ":sources need to be defined" unless hash.has_key?(:sources)
    bblock = SourceLibrary.new(name)
    bblock.set_sources(hash[:sources])
    bblock.set_includes(hash[:includes]) if hash.has_key?(:includes)
    bblock.set_tcs(hash[:toolchain]) if hash.has_key?(:toolchain)
    bblock.set_dependencies(hash[:dependencies]) if hash.has_key?(:dependencies)
    bblock.file_dependencies = hash[:file_dependencies] if hash.has_key?(:file_dependencies)
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

  def custom(name, hash)
    raise "not a hash" unless hash.is_a?(Hash)
    check_hash hash,[:execute]
    bblock = CustomBuildingBlock.new(name)
    bblock.set_actions(hash[:execute]) if hash.has_key?(:execute)
    all_blocks << bblock
  end

end

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
require 'cxxproject/eval_context'

class CxxProject2Rake
  begin
    include Rake::DSL
  rescue
    puts 'please update your rake installation'
  end

  attr_accessor :base, :all_tasks

  def initialize(projects, build_dir, toolchain, base='.')
    @projects = projects
    @base = base
    @build_dir = build_dir
    @toolchain = toolchain
    @rel_projects = @projects.map { |p| File.join(@base,p) }

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
    @all_tasks = instantiate_tasks()

    create_generic_tasks
    create_console_colorization
    create_multitask
    create_bail_on_first_task
  end

  def create_bail_on_first_task
    desc 'set bail on first error'
    task :bail_on_first_error do
      Rake::Task.bail_on_first_error = true
    end
  end

  def create_multitask
    desc 'set parallelization of multitask'
    task :multitask, :threads do |t, args|
      arg = args.threads
      if arg
        Rake::MultiTask.set_max_parallel_tasks(arg.to_i)
      end
    end
  end

  def create_console_colorization
    # default is on
    Cxxproject::ColorizingFormatter.enabled = true
    desc 'Toggle colorization of console output (use true|t|yes|y|1 for true ... everything else is false)'
    task :toggle_colorize, :on_off do |t, args|
      arg = args[:on_off] || 'false'
      on_off = arg.match(/(true|t|yes|y|1)$/) != nil
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

  def instantiate_tasks()#project_configs, build_dir, toolchain, base='.')
    cd(@base, :verbose => false) do
      @projects.each do |p|
        abort "project config #{p} cannot be found!" unless File.exists?(p)
      end
    end
    @log.debug "project_configs:"
    @projects.each { |c| @log.debug " *  #{c}" }
    register_projects()

    tasks = []

    #todo: sort ALL_BUILDING_BLOCKS (circular deps)
    ALL_BUILDING_BLOCKS.each do |name,block|
      prepare_block(block)
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

  def prepare_block(block)
    block.set_tcs(@toolchain) unless block.has_tcs?
    block.set_output_dir(Dir.pwd + "/" + @build_dir)
    block.set_config_files(@rel_projects)
    block.complete_init()
  end

  def register_projects()
    cd(@base,:verbose => false) do |b|
      @projects.each do |project_file|
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
    loadContext.all_blocks.each do |block|
      block.set_project_dir(Dir.pwd)
      if block.respond_to?(:sources) && block.sources.instance_of?(Rake::FileList)
        block.set_sources(block.sources.to_a)
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

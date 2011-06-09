require 'cxxproject/buildingblocks/has_dependencies_mixin'
require 'cxxproject/utils/dot/graph_writer'
require 'cxxproject/extensions/rake_ext'
require 'cxxproject/extensions/file_ext'
require 'cxxproject/ide_interface'

# no deprecated warning for rake >= 0.9.x
include Rake::DSL if defined?(Rake::DSL)

# stores all defined buildingblocks by name (the name should be unique)
ALL_BUILDING_BLOCKS = {}

class BuildingBlock
  include HasDependencies

  attr_reader :name
  attr_reader :graph_name
  attr_reader :config_files
  attr_reader :project_dir
  attr_reader :output_dir
  attr_reader :complete_output_dir

  @@verbose = false

  def self.idei
    @@idei ||= IDEInterface.new
  end
  def self.idei=(value)
    @@idei = value
  end

  def self.verbose
    @@verbose
  end
  def self.verbose=(value)
    @@verbose = value
  end

  def set_name(x)
    @name = x
    self
  end

  def set_tcs(x)
    @tcs = x
    self
  end

  def has_tcs?
    @tcs != nil
  end

  def tcs()
    raise "Toolchain settings must be set before!" if @tcs.nil?
    @tcs
  end

  def set_config_files(x)
    @config_files = x

    @config_files.each do |cf|
      Rake.application[cf].type = Rake::Task::CONFIG
    end

    self
  end

  def set_project_dir(x)
    @project_dir = x
    calc_complete_output_dir
    self
  end

  # if output dir is absolute, -L and -l is used for linker ("linux mode")
  def set_output_dir(x)
    @output_dir = x
    @output_dir_abs = File.is_absolute?(@output_dir)
    calc_complete_output_dir
    self
  end

  def calc_complete_output_dir
    if @output_dir_abs
      @complete_output_dir = @output_dir
    else
      @complete_output_dir = @project_dir + "/" + @output_dir
    end
  end

  def set_graph_name(x)
    @graph_name = x
    self
  end

  def initialize(name)
    @name = name
    @graph_name = name
    @config_files = []
    @project_dir = "."
    @output_dir = "."
    @complete_output_dir = "."
    @tcs = nil
    @output_dir_abs = false

    begin
      raise "building block already exists: #{name}" if ALL_BUILDING_BLOCKS.include?@name
      ALL_BUILDING_BLOCKS[@name] = self
    rescue Exception => e
      puts e unless self.instance_of?BinaryLibrary
    end
  end

  def complete_init()
  end

  def get_task_name()
    raise "this method must be implemented by decendants"
  end

  ##
  # convert all dependencies of a building block to rake task prerequisites (e.g. exe needs lib)
  #
  def setup_rake_dependencies(task)
    dependencies.reverse.each do |d|
      begin
        raise "ERROR: tried to add the dependencies of \"#{d}\" to \"#{@name}\" but such a building block could not be found!" unless ALL_BUILDING_BLOCKS[d]
        task.prerequisites.unshift(ALL_BUILDING_BLOCKS[d].get_task_name)
      rescue Exception => e
        puts e
        exit
      end
    end
    task
  end

  def add_output_dir_dependency(file, taskOfFile, addDirToCleanTask)
    outputdir = File.dirname(file)
    directory outputdir
    taskOfFile.enhance([outputdir])
    if addDirToCleanTask
      CLEAN.include(@complete_output_dir) unless CLEAN.include?(@complete_output_dir)
    end
  end

end

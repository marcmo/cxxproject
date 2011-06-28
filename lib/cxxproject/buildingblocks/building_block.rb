require 'cxxproject/buildingblocks/has_dependencies_mixin'
require 'cxxproject/utils/dot/graph_writer'
require 'cxxproject/ext/rake'
require 'cxxproject/ext/file'
require 'cxxproject/ide_interface'

# no deprecated warning for rake >= 0.9.x
include Rake::DSL if defined?(Rake::DSL)
module Cxxproject

# stores all defined buildingblocks by name (the name should be unique)
ALL_BUILDING_BLOCKS = {}

trap("INT") do
  Rake.application.idei.set_abort(true)
end

class BuildingBlock
  include HasDependencies

  attr_reader :name
  attr_reader :graph_name
  attr_reader :config_files
  attr_reader :project_dir
  attr_accessor :output_dir
  attr_reader :output_dir_abs

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
    self
  end

  # if output dir is absolute, -L and -l is used for linker ("linux mode")
  def set_output_dir(x)
    return self if output_dir

    @output_dir = x
    @output_dir_abs = File.is_absolute?(output_dir)
    self
  end

  def complete_output_dir
    @complete_output_dir ||= calc_complete_output_dir
  end

  def calc_complete_output_dir
    if @output_dir_abs
      output_dir
    else
      File.join(@project_dir,  output_dir)
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
    @tcs = nil
    @output_dir = nil
    @output_dir_abs = false
    @complete_output_dir = nil

    begin
      raise "building block already exists: #{name}" if ALL_BUILDING_BLOCKS.include?@name
      ALL_BUILDING_BLOCKS[@name] = self
    rescue Exception => e
      puts e unless self.instance_of?BinaryLibrary
    end
  end

  def complete_init()
    calc_direct_deps()
    if self.respond_to?(:init_calc_compiler_strings)
      init_calc_compiler_strings
    end
  end

  def complete_init2()
    if self.respond_to?(:calc_compiler_strings)
      calc_compiler_strings
    end
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
    d = File.dirname(file)
    directory d
    taskOfFile.enhance([d])
    if addDirToCleanTask
      CLEAN.include(complete_output_dir)
    end
  end

  def show_command(cmd, alternate)
    if RakeFileUtils.verbose
      puts cmd
    else
      puts alternate unless Rake::application.options.silent
    end
  end

  def read_file_or_empty_string(filename)
    begin
      return File.read(filename)
    rescue
      return ""
    end
  end

  def check_system_command(cmd)
    if $?.to_i != 0
      raise if RakeFileUtils.verbose # no need to print the cmd twice
      raise "System command failed: #{cmd}"
    end
  end

  def typed_file_task(type, *args, &block)
    t = file *args do
      block.call
    end
    t.type = type
    t.progress_count = 1
    return t
  end

  def remove_empty_strings_and_join(a, j=' ')
    return a.reject{|e|e.to_s.empty?}.join(j)
  end

  def catch_output(cmd)
    new_command = "#{cmd} 2>&1"
    return `#{new_command}`
  end
end
end

require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'

class Makefile < BuildingBlock
  include HasLibraries

  def set_target(x)
    @target = x
    self
  end

  def set_makefile(x)
    @makefile = x
    self
  end

  def get_makefile
    File.relFromTo(@makefile, @project_dir)
  end

  def get_target
    @target
  end

  def initialize(name)
    super(name)
    @target = "all"
    @makefile = nil
  end

  def get_task_name()
    get_makefile+"_"+get_target
  end





  def create_internal()
    mfile = get_makefile()
    cmd = [@tcs[:MAKE][:COMMAND], # make
      get_target, # all
      @tcs[:MAKE][:MAKE_FLAGS], # ??
      @tcs[:MAKE][:FLAGS], # -j
      @tcs[:MAKE][:DIR_FLAG], # -C
      File.dirname(mfile), # x/y
      @tcs[:MAKE][:FILE_FLAG], # -f
      File.basename(mfile) # x/y/makefile
    ].reject{|e| e == ""}.join(" ")
    mfileTask = task get_task_name do
      puts cmd
      consoleOutput = `#{cmd + " 2>&1"}`
      process_console_output(consoleOutput)
      raise "System command failed" if $?.to_i != 0
    end
    mfileTask.transparent_timestamp = true
    mfileTask.enhance(@config_files)

    # generate the clean task
    if not already_added_to_clean?(mfile+"Clean")
      cmdClean = [@tcs[:MAKE][:COMMAND], # make
        @tcs[:MAKE][:CLEAN], # clean
        @tcs[:MAKE][:DIR_FLAG], # -C
        File.dirname(mfile), # x/y
        @tcs[:MAKE][:FILE_FLAG], # -f
        File.basename(mfile) # x/y/makefile
      ].reject{|e| e == ""}.join(" ")
      mfileCleanTask = task mfile+"Clean" do
        puts cmdClean
        consoleOutput = `#{cmdClean + " 2>&1"}`
        process_console_output(consoleOutput)
        raise "System command failed" if $?.to_i != 0
      end
      add_task_to_clean_task(mfileCleanTask)
    end
    mfileTask
  end





end

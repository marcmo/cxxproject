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

  def convert_to_rake()
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
    mfileTask.type = Rake::Task::MAKE
    mfileTask.enhance(@config_files)

    # generate the clean task
    if not Rake.application["clean"].prerequisites.include?(mfile+"Clean")
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
      Rake.application["clean"].enhance([mfileCleanTask])
    end

    setup_rake_dependencies(mfileTask)
    mfileTask
  end

  def process_console_output(consoleOutput)
    if not consoleOutput.empty?
      puts consoleOutput

      if BuildingBlock.idei and $?.to_i != 0
        res = []
        res << @project_dir + "/" + get_makefile()
        res << 1
        res << 2
        if get_target != ""
          res << "Target \"#{get_target}\" failed"
        else
          res << "Failed"
        end
        BuildingBlock.idei.set_errors([res])
      end
    end
  end



end

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
    make = @tcs[:MAKE]
    cmd = remove_empty_strings_and_join([
      make[:COMMAND], # make
      get_target, # all
      make[:MAKE_FLAGS],
      make[:FLAGS], # -j
      make[:DIR_FLAG], # -C
      File.dirname(mfile), # x/y
      make[:FILE_FLAG], # -f
      File.basename(mfile) # x/y/makefile
    ])
    mfileTask = task get_task_name do
      show_command(cmd, cmd)
      process_console_output(catch_output(cmd))
      check_system_command(cmd)
    end
    mfileTask.transparent_timestamp = true
    mfileTask.type = Rake::Task::MAKE
    mfileTask.enhance(@config_files)

    create_clean_task(mfile)
    setup_rake_dependencies(mfileTask)
    mfileTask
  end

  def create_clean_task(mfile)
    # generate the clean task
    if not Rake.application["clean"].prerequisites.include?(mfile+"Clean")
      cmd = remove_empty_strings_and_join([@tcs[:MAKE][:COMMAND], # make
                                           @tcs[:MAKE][:CLEAN], # clean
                                           @tcs[:MAKE][:DIR_FLAG], # -C
                                           File.dirname(mfile), # x/y
                                           @tcs[:MAKE][:FILE_FLAG], # -f
                                           File.basename(mfile) # x/y/makefile
                                          ])
      mfileCleanTask = task mfile+"Clean" do
        show_command(cmd, cmd)
        process_console_output(catch_output(cmd))
        check_system_command(cmd)
      end
      Rake.application["clean"].enhance([mfileCleanTask])
    end
  end

  def process_console_output(consoleOutput)
    if not consoleOutput.empty?
      puts consoleOutput

      if $?.to_i != 0
        res = []
        res << @project_dir + "/" + get_makefile()
        res << 1
        res << 2
        if get_target != ""
          res << "Target \"#{get_target}\" failed"
        else
          res << "Failed"
        end
        Rake.application.idei.set_errors([res])
      end
    end
  end



end

require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/utils/printer'

module Cxxproject
  class Makefile < BuildingBlock
    include HasLibraries

    def set_target(x)
      @target = x
      self
    end
    
    def set_flags(x)
      @flags = x
      self
    end  
      
    def get_flags(x)
      @flags
    end    
      

    def set_makefile(x)
      @makefile = x
      self
    end

    def set_path_to(array)
      @path_to = array
      self
    end

    def get_makefile
      @makefile
    end

    def get_target
      @target
    end

    def initialize(mfile, mtarget)
      @target = mtarget != "" ? mtarget : "all"
      @makefile = mfile
      @flags = ""
      @path_to = []
      @num = Rake.application.makefile_number  
      super(get_task_name)
    end

    def get_task_name()
      "makefile (#{@num}): " + get_makefile + (get_target ? ("_"+get_target) : "")    
    end

    def calc_pathes_to_projects
      vars = []
      @path_to.each do |p|
        bb = ALL_BUILDING_BLOCKS[p]
        if bb
          pref = File.rel_from_to_project(@project_dir,bb.project_dir)
          rex = Regexp.new "\\.\\.\\/(.*)#{p}"
          var = pref.scan(rex)[0]
          if var
            vars << "PATH_TO_#{p}=#{var[0]}"
          end
        else
          Printer.printError "Error: Project '#{p}' not found for makefile #{@project_dir}/#{@makefile}"
          ExitHelper.exit(1)
        end
      end
      vars.join(" ")
    end

    def convert_to_rake()
      pathes_to_projects = calc_pathes_to_projects
    
      mfile = get_makefile()
      make = @tcs[:MAKE]
      cmd = remove_empty_strings_and_join([
        make[:COMMAND], # make
        get_target, # all
        make[:MAKE_FLAGS],
        @flags, # -j
        make[:DIR_FLAG], # -C
        File.dirname(mfile), # x/y
        make[:FILE_FLAG], # -f
        File.basename(mfile), # x/y/makefile
        pathes_to_projects
      ])
      
      
      mfileTask = task get_task_name do
        Dir.chdir(@project_dir) do
          check_config_file
          consoleOutput = catch_output(cmd)
          process_result(cmd, consoleOutput)
        end
      end
      mfileTask.transparent_timestamp = true
      mfileTask.type = Rake::Task::MAKE
      mfileTask.enhance(@config_files)

      create_clean_task(@project_dir+"/"+mfile, pathes_to_projects)
      setup_rake_dependencies(mfileTask)
      mfileTask
    end

    def create_clean_task(mfile, pathes_to_projects)
      # generate the clean task
      if not Rake.application["clean"].prerequisites.include?(mfile+"Clean")
        cmd = remove_empty_strings_and_join([@tcs[:MAKE][:COMMAND], # make
          @tcs[:MAKE][:CLEAN], # clean
          @tcs[:MAKE][:DIR_FLAG], # -C
          File.dirname(mfile), # x/y
          @tcs[:MAKE][:FILE_FLAG], # -f
          File.basename(mfile), # x/y/makefile
          pathes_to_projects
        ])
        mfileCleanTask = task mfile+"Clean" do
          Dir.chdir(@project_dir) do
            check_config_file
            consoleOutput = catch_output(cmd)
            process_result(cmd, consoleOutput)
          end
        end
        Rake.application["clean"].enhance([mfileCleanTask])
      end
    end

    def process_console_output(consoleOutput, errorParser)
      if not consoleOutput.empty?
        puts consoleOutput

        if $?.success? == false
          res = ErrorDesc.new
          res.file_name = @project_dir + "/" + get_makefile()
          res.line_number = 1
          res.severity = ErrorParser::SEVERITY_ERROR
          if get_target != ""
            res.message = "Target \"#{get_target}\" failed"
          else
            res.message = "Failed"
          end
          Rake.application.idei.set_errors([res])
        end
      end
    end



  end
end

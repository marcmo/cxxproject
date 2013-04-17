require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'
require 'cxxproject/utils/process'
require 'cxxproject/utils/utils'

module Cxxproject
  class SourceLibrary < BuildingBlock
    include HasLibraries
    include HasSources
    include HasIncludes

    def initialize(name)
      super(name)
    end

    def complete_init()
      if @output_dir_abs
        add_lib_element(HasLibraries::SEARCH_PATH, File.join(@output_dir, 'libs'), true)
        add_lib_element(HasLibraries::LIB, @name, true)
      else
        add_lib_element(HasLibraries::LIB_WITH_PATH, File.join(@output_dir,"lib#{@name}.a"), true)
      end
      super
    end

    def get_archive_name() # relative path
      return @archive_name if @archive_name
      parts = [@output_dir]

      if @output_dir_abs
        parts = [@output_dir_relPath] if @output_dir_relPath
        parts << 'libs'
      end

      parts << "lib#{@name}.a"

      @archive_name = File.join(parts)
      @archive_name
    end

    def get_task_name() # full path
      return @task_name if @task_name

      parts = [@output_dir]
      parts << 'libs' if @output_dir_abs
      parts << "lib#{@name}.a"
      @task_name = File.join(parts)
      @task_name = @project_dir + "/" + @task_name unless @output_dir_abs
      @task_name
    end
    
    # task that will link the given object files to a static lib
    #
    def convert_to_rake()
      object_multitask = prepare_tasks_for_objects()
      archiver = @tcs[:ARCHIVER]

      res = typed_file_task Rake::Task::LIBRARY, get_task_name => object_multitask do
        dir = @project_dir
        objs = @objects
        aname = get_archive_name        
          
        if @output_dir_abs
          dir = @output_dir
          prefix = File.rel_from_to_project(@project_dir, @output_dir)
          objs.map! { |m| m[prefix.length..-1] }
          aname = aname[prefix.length..-1]
        end
        
        if (objs.length != 0 or not File.exist?(get_task_name))
          Dir.chdir(dir) do
            if File.exists?(aname)
              FileUtils.rm(aname)
            else 
              d = File.dirname(aname)
              FileUtils.mkdir_p(d)
            end
            
            cmd = [archiver[:COMMAND]] # ar
            cmd += archiver[:ARCHIVE_FLAGS].split(" ")
            cmd += Cxxproject::Utils::flagSplit(archiver[:FLAGS]) # --all_load
            cmd << aname # -o debug/x.exe
            cmd += objs
  
            if Cxxproject::Utils.old_ruby?
              cmd.map! {|c| ((c.include?" ") ? ("\""+c+"\"") : c )}
  
              cmdLine = cmd.join(" ")
              if cmdLine.length > 8000
                inputName = aname+".tmp"
                File.open(inputName,"wb") { |f| f.write(cmd[1..-1].join(" ")) }
                success, consoleOutput = ProcessHelper.safeExecute() { `#{archiver[:COMMAND] + " @" + inputName}` }
              else
                success, consoleOutput = ProcessHelper.safeExecute() { `#{cmd.join(" ")} 2>&1` }
              end
            else
              rd, wr = IO.pipe
              cmd << {
               :err=>wr,
               :out=>wr
              }
              success, consoleOutput = ProcessHelper.safeExecute() { sp = spawn(*cmd); ProcessHelper.readOutput(sp, rd, wr) }
              cmd.pop
            end
  
            process_result(cmd, consoleOutput, archiver[:ERROR_PARSER], "Creating #{aname}", success)
  
            check_config_file()
          end
        end
      end
      enhance_with_additional_files(res)
      
      if not Rake.application["clean"].prerequisites.include?(get_task_name+"Clean")
        cleanTask = task get_task_name+"Clean" do
          Dir.chdir(@project_dir) do 
            if (calc_sources_to_build(true).length != 0 or not File.exist?(get_task_name))
              if (@output_dir_abs)
                FileUtils.rm_rf(file)
              else
                FileUtils.rm_rf(complete_output_dir)
              end
            end
          end
        end        
        
        Rake.application["clean"].enhance([cleanTask])
      end
      
      add_grouping_tasks(get_task_name)

      setup_rake_dependencies(res, object_multitask)
      return res
    end

    def add_grouping_tasks(archive)
      namespace 'lib' do
        desc archive
        task @name => archive
      end
    end
  end
end

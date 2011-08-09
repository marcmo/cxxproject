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
        libs_to_search << @name
        lib_searchpaths << File.join(@output_dir, 'libs')
      else
        libs_with_path << File.join(@output_dir,"lib#{@name}.a")
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
          dir = @output_dir + "/objects/" + @name
          prefix = File.rel_from_to_project(@project_dir, @output_dir)
          lengthToObj = (prefix +  "/objects/" + @name).length
          objs.map! { |m| m[lengthToObj..-1] }
          aname = "../../"+aname[prefix.length..-1]
        end
      
        Dir.chdir(dir) do

          FileUtils.rm(aname) if File.exists?(aname)
          cmd = [archiver[:COMMAND]] # ar
          cmd += archiver[:ARCHIVE_FLAGS].split(" ")
          cmd += archiver[:FLAGS].split(" ") # --all_load
          cmd << aname # -o debug/x.exe
          cmd += objs

          if Cxxproject::Utils.old_ruby?
            cmdLine = cmd.join(" ")
            if cmdLine.length > 8000
              inputName = aname+".tmp"
              File.open(inputName,"wb") { |f| f.write(cmd[1..-1].join(" ")) }
              consoleOutput = `#{archiver[:COMMAND] + " @" + inputName}`
            else
              consoleOutput = `#{cmd.join(" ")} 2>&1`
            end
          else
            rd, wr = IO.pipe
            cmd << {
             :err=>wr,
             :out=>wr
            }
            sp = spawn(*cmd)
            cmd.pop
            
            consoleOutput = ProcessHelper.readOutput(sp, rd, wr)
          end

          process_result(cmd, consoleOutput, archiver[:ERROR_PARSER], "Creating #{File.basename(aname)}")
        end
      end

      enhance_with_additional_files(res)
      add_output_dir_dependency(get_task_name, res, true)

      add_grouping_tasks(get_task_name)

      setup_rake_dependencies(res)
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

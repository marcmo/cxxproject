require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'

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

    def get_archive_name()
      return @archive_name if @archive_name
      parts = [@output_dir]
      parts << 'libs' if @output_dir_abs
      parts << "lib#{@name}.a"

      @archive_name = File.join(parts)
      @archive_name
    end

    def get_task_name()
      return @task_name if @task_name 
      @task_name = get_archive_name
      @task_name = @project_dir + "/" + @task_name unless @output_dir_abs
      @task_name
    end

    # task that will link the given object files to a static lib
    #
    def convert_to_rake()
      object_multitask = prepare_tasks_for_objects()

      archiver = @tcs[:ARCHIVER]

      res = typed_file_task Rake::Task::LIBRARY, get_task_name => object_multitask do
        Dir.chdir(@project_dir) do
          cmd = remove_empty_strings_and_join([
            archiver[:COMMAND], # ar
            archiver[:ARCHIVE_FLAGS], # -rc
            archiver[:FLAGS],
            get_archive_name, # debug/x.a
            get_object_filenames # debug/src/abc.o debug/src/xy.o
          ])

          show_command(cmd, "Creating #{get_archive_name}")
          process_console_output(catch_output(cmd), @tcs[:ARCHIVER][:ERROR_PARSER])
          check_system_command(cmd)
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

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

    attr_reader :whole_archive

    def initialize(name, whole_archive=false)
      super(name)
      @whole_archive = whole_archive
    end

    def complete_init()
      if @output_dir_abs
        add_lib_element(HasLibraries::LIB, @name, true)
        add_lib_element(HasLibraries::SEARCH_PATH, File.join(@output_dir, 'libs'), true)
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

    def calc_command_line
      objs = @objects
       if @output_dir_abs
        prefix = File.rel_from_to_project(@project_dir, @output_dir)
#        objs.map! { |m| m[prefix.length..-1] }
      end
      archiver = @tcs[:ARCHIVER]
      cmd = [archiver[:COMMAND]] # ar
      cmd += archiver[:ARCHIVE_FLAGS].split(" ")
      cmd += archiver[:FLAGS]
      cmd << calc_archive_name # -o debug/x.exe
      cmd += objs
    end

    def calc_archive_name
      aname = get_archive_name
#      if @output_dir_abs
#        prefix = File.rel_from_to_project(@project_dir, @output_dir)
#        aname = aname[prefix.length..-1]
#      end
      return aname
    end

    # task that will link the given object files to a static lib
    #
    def convert_to_rake()
      object_multitask = prepare_tasks_for_objects()
      archiver = @tcs[:ARCHIVER]

      res = typed_file_task Rake::Task::LIBRARY, get_task_name => object_multitask do
        cmd = calc_command_line
        aname = calc_archive_name
        Dir.chdir(@project_dir) do
          FileUtils.rm(aname) if File.exists?(aname)
#          cmd.map! {|c| c.include?(' ') ? "\"#{c}\"" : c }
          rd, wr = IO.pipe
          cmd << {
            :err => wr,
            :out => wr
          }
          sp = spawn(*cmd)
          cmd.pop

          consoleOutput = ProcessHelper.readOutput(sp, rd, wr)

          process_result(cmd, consoleOutput, @tcs[:ARCHIVER][:ERROR_PARSER], "Creating #{aname}")

          check_config_file()
        end
      end
      enhance_with_additional_files(res)
      add_output_dir_dependency(get_task_name, res, true)

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

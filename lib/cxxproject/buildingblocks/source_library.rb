require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'

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
  end

  def get_archive_name()
    parts = [complete_output_dir]
    parts << 'libs' if @output_dir_abs
    parts << "lib#{@name}.a"

    File.relFromTo(File.join(parts), @project_dir)
  end

  def get_task_name()
    get_archive_name
  end

  # task that will link the given object files to a static lib
  #
  def convert_to_rake()
    calc_compiler_strings()
    objects, object_multitask = create_tasks_for_objects()
    archive = get_archive_name()

    cmd = remove_empty_strings_and_join([
      @tcs[:ARCHIVER][:COMMAND], # ar
      @tcs[:ARCHIVER][:ARCHIVE_FLAGS], # -rc
      @tcs[:ARCHIVER][:FLAGS],
      archive, # debug/x.a
      remove_empty_strings_and_join(objects) # debug/src/abc.o debug/src/xy.o
    ])

    res = typed_file_task Rake::Task::LIBRARY, archive => object_multitask do
      show_command(cmd, "Creating #{archive}")
      process_console_output(catch_output(cmd), @tcs[:ARCHIVER][:ERROR_PARSER])
      check_system_command(cmd)
    end
    enhance_with_additional_files(res)
    add_output_dir_dependency(archive, res, true)
    add_grouping_tasks(archive)
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

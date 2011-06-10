require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'

require 'tmpdir'

class Executable < BuildingBlock
  include HasLibraries
  include HasSources
  include HasIncludes

  attr_reader :linker_script
  attr_reader :mapfile
  attr_reader :output_file

  def set_linker_script(x)
    @linker_script = x
    self
  end

  def set_mapfile(x)
    @mapfile = x
    self
  end

  # set during creating the task - note: depends on the used tcs
  def set_output_file(x)
    @output_file = x
    self
  end

  def initialize(name)
    super(name)
    @linker_script = nil
    @mapfile = nil
  end

  def linker_libs_string
    @linkerString ||= ""
  end


  def get_executable_name()
    parts = [complete_output_dir]
    parts << 'exes' if @output_dir_abs
    parts << "#{@name}#{@tcs[:LINKER][:OUTPUT_ENDING]}"

    File.relFromTo(File.join(parts), @project_dir)
  end

  def get_task_name()
    get_executable_name()
  end

  def include_if_new(lookup, target, key, value)
    if not lookup.include?(key)
      lookup << key
      target << value
    end
  end

  def calc_linker_lib_string_for_dependency(d, path_arrays, res)
    d.lib_searchpaths.each do |k|
      tmp = File.relFromTo(k, d.project_dir)
      include_if_new(path_arrays[0], res, tmp, "#{@tcs[:LINKER][:LIB_PATH_FLAG]}#{tmp}")
    end
    d.libs_to_search.each do |k|
      include_if_new(path_arrays[1], res, k, "#{@tcs[:LINKER][:LIB_FLAG]}#{k}")
    end
    d.user_libs.each do |k|
      include_if_new(path_arrays[2], res, k, "#{@tcs[:LINKER][:USER_LIB_FLAG]}#{k}")
    end
    d.libs_with_path.each do |k|
      tmp = File.relFromTo(k, d.project_dir)
      include_if_new(path_arrays[3], res, tmp, tmp)
    end
  end

  def calc_linker_lib_string
    # calc linkerLibString - order is important, duplicates are removed
    lib_searchpaths_array = []
    libs_to_search_array = []
    user_libs_array = []
    libs_with_path_array = []
    res = []
    all_dependencies.map{|e|ALL_BUILDING_BLOCKS[e]}.each do |d|
      next if not HasLibraries === d
      calc_linker_lib_string_for_dependency(d, [lib_searchpaths_array, libs_to_search_array, user_libs_array, libs_with_path_array], res)
    end
    res
  end

  # create a task that will link an executable from a set of object files
  #
  def convert_to_rake()
    calc_compiler_strings()
    objects, object_multitask = create_tasks_for_objects()

    script_file, script = calc_linker_script

    cmd = remove_empty_strings_and_join([@tcs[:LINKER][:COMMAND], # g++
      @tcs[:LINKER][:MUST_FLAGS], @tcs[:LINKER][:FLAGS], # --all_load
      @tcs[:LINKER][:EXE_FLAG], get_executable_name, # -o debug/x.exe
      remove_empty_strings_and_join(objects), # debug/src/abc.o debug/src/xy.o
      script,
      mapfileString = @mapfile ? "#{@tcs[:LINKER][:MAP_FILE_FLAG]} >#{File.relFromTo(@mapfile, complete_output_dir)}" : "", # -Wl,-m6 > xy.map
      @tcs[:LINKER][:LIB_PREFIX_FLAGS], # "-Wl,--whole-archive "
      remove_empty_strings_and_join(calc_linker_lib_string),
      @tcs[:LINKER][:LIB_POSTFIX_FLAGS] # "-Wl,--no-whole-archive "
    ])

    return create_task(object_multitask, cmd, script_file)
  end

  def calc_linker_script
    script_file = ""
    script = ""
    if @linker_script
      script_file = File.relFromTo(@linker_script, @project_dir)
      script = "#{@tcs[:LINKER][:SCRIPT]} #{script_file}"  # -T xy/xy.dld
    end
    return script_file, script
  end

  def create_task(object_multitask, cmd, script_file)
    executable = get_executable_name
    res = typed_file_task Rake::Task::EXECUTABLE, executable => object_multitask do
      show_command(cmd, "Linking #{executable}")
      # TempFile used, because some compilers, e.g. diab, uses ">" for piping to map files:
      consoleOutput = `#{cmd + " 2>" + get_temp_filename}`
      consoleOutput.concat(read_file_or_empty_string(get_temp_filename))
      process_console_output(consoleOutput, @tcs[:LINKER][:ERROR_PARSER])
      check_system_command(cmd)
    end
    res.enhance(@config_files)
    res.enhance([script_file]) unless script_file.empty?
    add_output_dir_dependency(executable, res, true)

    add_grouping_tasks(executable)
    setup_rake_dependencies(res)
    return res
  end

  def add_grouping_tasks(executable)
    namespace 'exe' do
      desc executable
      task @name => executable
    end
    create_run_task(executable, @name)
  end

  def create_run_task(executable, name)
    namespace 'run' do
      desc "run executable #{executable}"
      res = task name => executable do
        sh "#{executable}"
      end
      res.type = Rake::Task::RUN
      res
    end
  end

  def get_temp_filename
    Dir.tmpdir + "/lake.tmp"
  end

end

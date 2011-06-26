require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'

require 'tmpdir'
require 'set'
module Cxxproject

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

    def collect_unique(array, set)
      ret = []
      array.each do |v|
        if set.add?(v)
          ret << v
        end
      end
      ret
    end
    
    def calc_linker_lib_string_for_dependency(d, s1, s2, s3, s4)
      res = []
      linker = @tcs[:LINKER]
      collect_unique(d.lib_searchpaths, s1).each do |v|
        tmp = File.relFromTo(v, d.project_dir)
        res << "#{linker[:LIB_PATH_FLAG]}#{tmp}"
      end
      collect_unique(d.libs_to_search, s2).each do |v|
        res << "#{linker[:LIB_FLAG]}#{v}"
      end
      collect_unique(d.user_libs, s3).each do |v|
        res << "#{linker[:USER_LIB_FLAG]}#{v}"
      end
      collect_unique(d.libs_with_path, s4).each do |v|
        res <<  File.relFromTo(v, d.project_dir)
      end
      res
    end

    def calc_linker_lib_string
      # calc linkerLibString - order is important, duplicates are removed
      s1 = Set.new
      s2 = Set.new
      s3 = Set.new
      s4 = Set.new
      res = []
      all_dependencies.each do |d|
        next if not HasLibraries === d
        res += calc_linker_lib_string_for_dependency(d, s1, s2, s3, s4)
      end
      res
    end

    # create a task that will link an executable from a set of object files
    #
    def convert_to_rake()
      calc_compiler_strings()
      objects, object_multitask = create_tasks_for_objects()

      script_file, script = calc_linker_script
      linker = @tcs[:LINKER]
      cmd = remove_empty_strings_and_join([
        linker[:COMMAND], # g++
        linker[:MUST_FLAGS],
        linker[:FLAGS], # --all_load
        linker[:EXE_FLAG],
        get_executable_name, # -o debug/x.exe
        remove_empty_strings_and_join(objects), # debug/src/abc.o debug/src/xy.o
        script,
        mapfileString = @mapfile ? "#{linker[:MAP_FILE_FLAG]} >#{File.relFromTo(@mapfile, complete_output_dir)}" : "", # -Wl,-m6 > xy.map
        linker[:LIB_PREFIX_FLAGS], # "-Wl,--whole-archive "
        remove_empty_strings_and_join(calc_linker_lib_string),
        linker[:LIB_POSTFIX_FLAGS] # "-Wl,--no-whole-archive "
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
        res = task name => executable do |t|
          run_command(t, executable)
        end
        res.type = Rake::Task::RUN
        res
      end
    end

    def run_command(task, command)
      sh "#{command}"
    end

    def get_temp_filename
      Dir.tmpdir + "/lake.tmp"
    end

  end
end

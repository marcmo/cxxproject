require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'
require 'cxxproject/utils/process'

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


    def get_executable_name() # relative path
      return @exe_name if @exe_name

      parts = [@output_dir]

      if @output_dir_abs
        parts = [@output_dir_relPath] if @output_dir_relPath
        parts << 'exes'
      end

      parts << "#{@name}#{@tcs[:LINKER][:OUTPUT_ENDING]}"

      @exe_name = File.join(parts)
      @exe_name
    end

    def get_task_name() # full path
      return @task_name if @task_name

      parts = [@output_dir]
      parts << 'exes' if @output_dir_abs
      parts << "#{@name}#{@tcs[:LINKER][:OUTPUT_ENDING]}"
      @task_name = File.join(parts)

      @task_name = @project_dir + "/" + @task_name unless @output_dir_abs
      @task_name
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
      prefix = File.rel_from_to_project(@project_dir,d.project_dir)
      linker = @tcs[:LINKER]
      collect_unique(d.lib_searchpaths, s1).each do |v|
        tmp = File.add_prefix(prefix, v)
        res << "#{linker[:LIB_PATH_FLAG]}#{tmp}"
      end if prefix
      collect_unique(d.libs_to_search, s2).each do |v|
        res << "#{linker[:LIB_FLAG]}#{v}"
      end
      collect_unique(d.user_libs, s3).each do |v|
        res << "#{linker[:USER_LIB_FLAG]}#{v}"
      end
      collect_unique(d.libs_with_path, s4).each do |v|
        res <<  File.add_prefix(prefix, v)
      end if prefix
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
      object_multitask = prepare_tasks_for_objects()

      linker = @tcs[:LINKER]

      res = typed_file_task Rake::Task::EXECUTABLE, get_task_name => object_multitask do
        Dir.chdir(@project_dir) do

          cmd = [linker[:COMMAND]] # g++
          cmd += linker[:MUST_FLAGS].split(" ")
          cmd += linker[:FLAGS].split(" ") # --all_load
          cmd << linker[:EXE_FLAG]
          cmd << get_executable_name # -o debug/x.exe
          cmd += @objects # debug/src/abc.o debug/src/xy.o
          cmd << linker[:SCRIPT] if @linker_script # -T
          cmd << @linker_script if @linker_script # xy/xy.dld
          cmd << linker[:MAP_FILE_FLAG] if @mapfile # -Wl,-m6
          cmd += linker[:LIB_PREFIX_FLAGS].split(" ") # "-Wl,--whole-archive "
          cmd += calc_linker_lib_string
          cmd += linker[:LIB_POSTFIX_FLAGS].split(" ") # "-Wl,--no-whole-archive "

          rd, wr = IO.pipe
          sp = spawn(*cmd,
            {
             :out=> @mapfile ? "#{@output_dir}/#{@mapfile}" : :err, # > xy.map
             :err=>wr
            })

          # for console print
          cmd << " >#{@output_dir}/#{@mapfile}" if @mapfile

          consoleOutput = ProcessHelper.readOutput(sp, rd, wr)
          show_command(cmd, "Linking #{get_executable_name}")
          process_console_output(consoleOutput, @tcs[:LINKER][:ERROR_PARSER])
          check_system_command(cmd)
        end
      end
      res.enhance(transitive_config_files)
      res.enhance([@project_dir + "/" + @linker_script]) if @linker_script
      add_output_dir_dependency(get_task_name, res, true)

      add_grouping_tasks(get_task_name)
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

  end
end

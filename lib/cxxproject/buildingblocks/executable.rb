require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'
require 'cxxproject/utils/process'
require 'cxxproject/utils/utils'
require 'cxxproject/ext/stdout'
require 'cxxproject/utils/valgrind'

require 'tmpdir'
require 'set'
require 'etc'

module Cxxproject

  class Executable < BuildingBlock
    include HasLibraries
    include HasSources
    include HasIncludes

    def set_linker_script(x)
      @linker_script = x
      self
    end

    def set_mapfile(x)
      @mapfile = x
      self
    end

    def initialize(name)
      super(name)
      @linker_script = nil
      @mapfile = nil
    end

    def set_executable_name(name) # ensure it's relative
      @exe_name = name
    end

    def get_executable_name() # relative path
      return @exe_name if @exe_name

      parts = [@output_dir]

      if @output_dir_abs
        parts = [@output_dir_relPath] if @output_dir_relPath
      end

      parts << "#{@name}#{@tcs[:LINKER][:OUTPUT_ENDING]}"

      @exe_name = File.join(parts)
      @exe_name
    end

    def get_task_name() # full path
      @project_dir + "/" + get_executable_name
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

    def adaptPath(v, d, prefix)
      tmp = nil
      if File.is_absolute?(v)
        tmp = v
      else
        prefix ||= File.rel_from_to_project(@project_dir,d.project_dir)
        tmp = File.add_prefix(prefix, v)
      end
      tmp = "\"" + tmp + "\"" if tmp.include?(" ")
      [tmp, prefix]
    end

    def linker_lib_string()
      @lib_path_set = Set.new
      @dep_set = Set.new
      calc_linker_lib_string_recursive(self)
    end

    def calc_linker_lib_string_recursive(d)
      res = []

      return res if @dep_set.include?d
      @dep_set << d

      if HasLibraries === d
        prefix = nil
        linker = @tcs[:LINKER]

        d.lib_elements.each do |elem|
          case elem[0]
            when HasLibraries::LIB
              res << "#{linker[:LIB_FLAG]}#{elem[1]}"
            when HasLibraries::USERLIB
              res << "#{linker[:USER_LIB_FLAG]}#{elem[1]}"
            when HasLibraries::LIB_WITH_PATH
              tmp, prefix = adaptPath(elem[1], d, prefix)
              res <<  tmp
            when HasLibraries::SEARCH_PATH
              tmp, prefix = adaptPath(elem[1], d, prefix)
              if not @lib_path_set.include?tmp
                @lib_path_set << tmp
                res << "#{linker[:LIB_PATH_FLAG]}#{tmp}"
              end
            when HasLibraries::DEPENDENCY
              if ALL_BUILDING_BLOCKS.include?elem[1]
                bb = ALL_BUILDING_BLOCKS[elem[1]]
                res += calc_linker_lib_string_recursive(bb)
              end
          end
        end
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
          cmd += linker[:FLAGS].gsub(/\"/,"").split(" ") # double quotes within string do not work on windows...
          cmd << linker[:EXE_FLAG]
          cmd << get_executable_name # -o debug/x.exe
          cmd += @objects
          cmd << linker[:SCRIPT] if @linker_script # -T
          cmd << @linker_script if @linker_script # xy/xy.dld
          cmd << linker[:MAP_FILE_FLAG] if @mapfile # -Wl,-m6
          cmd += linker[:LIB_PREFIX_FLAGS].split(" ") # "-Wl,--whole-archive "
          cmd += linker_lib_string
          cmd += linker[:LIB_POSTFIX_FLAGS].split(" ") # "-Wl,--no-whole-archive "

          mapfileStr = @mapfile ? " >#{@mapfile}" : ""
          if Cxxproject::Utils.old_ruby?
            cmd.map! {|c| ((c.include?(" ")) ? ("\""+c+"\"") : c )}

            # TempFile used, because some compilers, e.g. diab, uses ">" for piping to map files:
            cmdLinePrint = cmd.join(" ")
            cmdLine = cmdLinePrint + " 2>" + get_temp_filename
            if cmdLine.length > 8000
              inputName = get_executable_name+".tmp"
              File.open(inputName,"wb") { |f| f.write(cmd[1..-1].join(" ")) }
              inputName = "\""+inputName+"\"" if inputName.include?" "
              strCmd = "#{linker[:COMMAND] + " @" + inputName + mapfileStr + " 2>" + get_temp_filename}"
            else
              strCmd = "#{cmd.join(" ") + mapfileStr + " 2>" + get_temp_filename}"
            end
            printCmd(cmdLinePrint, "Linking #{get_executable_name}", false)
            consoleOutput = `#{strCmd}`
            consoleOutput.concat(read_file_or_empty_string(get_temp_filename))
          else
            rd, wr = IO.pipe
            cmdLinePrint = cmd
            printCmd(cmdLinePrint, "Linking #{get_executable_name}", false)
            cmd << {
             :out=> @mapfile ? "#{@mapfile}" : wr, # > xy.map
             :err=>wr
            }
            sp = spawn(*cmd)
            cmd.pop

            # for console print
            cmd << " >#{@mapfile}" if @mapfile
            consoleOutput = ProcessHelper.readOutput(sp, rd, wr)
          end

          process_result(cmdLinePrint, consoleOutput, linker[:ERROR_PARSER], nil)

          check_config_file()
        end
      end
      res.immediate_output = true
      res.enhance(@config_files)
      res.enhance([@project_dir + "/" + @linker_script]) if @linker_script

      add_output_dir_dependency(get_task_name, res, true)
      add_grouping_tasks(get_task_name)
      setup_rake_dependencies(res, object_multitask)

      # check that all source libs are checked even if they are not a real rake dependency (can happen if "build this project only")
      begin
        libChecker = task get_task_name+"LibChecker" do
          if File.exists?(get_task_name) # otherwise the task will be executed anyway
            all_dependencies.each do |bb|
              if bb and SourceLibrary === bb
                f = bb.get_task_name # = abs path of library
                if not File.exists?(f) or File.mtime(f) > File.mtime(get_task_name)
                  def res.needed?
                    true
                  end
                  break
                end
              end
            end
          end
        end
      rescue
        def res.needed?
          true
        end
      end
      libChecker.transparent_timestamp = true
      res.enhance([libChecker])

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
          sh executable
        end
        res.type = Rake::Task::RUN
        res
      end
      if Valgrind::available?
        namespace 'valgrind' do
          desc "run executable #{executable} with valgrind"
          res = task name => executable do |t|
            sh "valgrind #{executable}"
          end
          res.type = Rake::Task::RUN
          res
        end
      end
    end

    def get_temp_filename
      Dir.tmpdir + "/lake.tmp"
    end

  end
end

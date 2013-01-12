require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'
require 'cxxproject/buildingblocks/has_includes_mixin'
require 'cxxproject/utils/process'
require 'cxxproject/utils/utils'
require 'cxxproject/ext/stdout'

require 'tmpdir'
require 'set'
require 'etc'

module Cxxproject 
  class SharedLibrary < BuildingBlock
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
    def complete_init()
      if @output_dir_abs
        add_lib_element(HasLibraries::LIB, @name, true)
        add_lib_element(HasLibraries::SEARCH_PATH, File.join(@output_dir, 'libs'), true)
      else
        add_lib_element(HasLibraries::LIB_WITH_PATH, File.join(@output_dir,"lib#{@name}.a"), true)
      end
      super
    end
    
    def set_library_name(name) # ensure it's relative
      @lib_name = name
    end

    def get_library_name() # relative path
      return @lib_name if @lib_name

      parts = [@output_dir]

      if @output_dir_abs
        parts = [@output_dir_relPath] if @output_dir_relPath
	parts << 'libs'
      end
      parts << "#{@tcs[:LINKER][:SHA_PREFIX]}#{@name}#{@tcs[:LINKER][:SHA_ENDING]}"

      @lib_name = File.join(parts)
      @lib_name
    end

    def get_task_name() # full path
      @project_dir + "/" + get_library_name
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

    def adapt_path(v, d, prefix)
      tmp = nil
      if File.is_absolute?(v)
        tmp = v
      else
        prefix ||= File.rel_from_to_project(@project_dir, d.project_dir)
        tmp = File.add_prefix(prefix, v)
      end
      [tmp, prefix]
    end

    def linker_lib_string(linker)
      lib_path_set = Set.new
      deps = collect_dependencies
      res = []
      deps.each do |d|
	handle_whole_archive(d, res, linker, :START_OF_WHOLE_ARCHIVE)
        if HasLibraries === d and d != self
          d.lib_elements.each do |elem|
            case elem[0]
            when HasLibraries::LIB
              res.push("#{linker[:LIB_FLAG]}#{elem[1]}")
            when HasLibraries::USERLIB
              res.push("#{linker[:USER_LIB_FLAG]}#{elem[1]}")
            when HasLibraries::LIB_WITH_PATH
              tmp, prefix = adapt_path(elem[1], d, prefix)
              res.push(tmp)
            when HasLibraries::SEARCH_PATH
              tmp, prefix = adapt_path(elem[1], d, prefix)
              if not lib_path_set.include?(tmp)
                lib_path_set << tmp
                res.push("#{linker[:LIB_PATH_FLAG]}#{tmp}")
              end
            end
          end
        end
        handle_whole_archive(d, res, linker, :END_OF_WHOLE_ARCHIVE)
      end
      res
    end

    # res the array with command line arguments that is used as result
    # linker the linker hash
    # sym the symbol that is used to fish out a value from the linker
    def handle_whole_archive(building_block, res, linker, sym)
      if building_block.instance_of?(SourceLibrary)
        if building_block.whole_archive
          res.push(linker[sym]) if linker[sym] and !linker[sym].empty?
        end
      end
    end

    # create a task that will link a shared library  from a set of object files
    #
    def convert_to_rake()
      object_multitask = prepare_tasks_for_objects()

      linker = @tcs[:LINKER]

      res = typed_file_task Rake::Task::SHALIBRARY, get_task_name => object_multitask do
        Dir.chdir(@project_dir) do
          cmd = [linker[:COMMAND]] # g++
          cmd += linker[:MUST_FLAGS].split(" ")
          cmd += linker[:FLAGS]
          cmd << linker[:SHARED_FLAG]
          cmd << linker[:OUTPUT_FLAG]
          cmd << get_library_name 
          cmd += @objects
          cmd << linker[:SCRIPT] if @linker_script # -T
          cmd << @linker_script if @linker_script # xy/xy.dld
          cmd << linker[:MAP_FILE_FLAG] if @mapfile # -Wl,-m6
          cmd += linker[:LIB_PREFIX_FLAGS].split(" ") # TODO ... is this still needed e.g. for diab
          cmd += linker_lib_string(@tcs[:LINKER])
          cmd += linker[:LIB_POSTFIX_FLAGS].split(" ") # TODO ... is this still needed e.g. for diab

          mapfileStr = @mapfile ? " >#{@mapfile}" : ""
          rd, wr = IO.pipe
          cmdLinePrint = cmd
          printCmd(cmdLinePrint, "Linking #{get_library_name}", false)
          cmd << {
            :out=> @mapfile ? "#{@mapfile}" : wr, # > xy.map
            :err=>wr
          }
          sp = spawn(*cmd)
          cmd.pop

          # for console print
          cmd << " >#{@mapfile}" if @mapfile
          consoleOutput = ProcessHelper.readOutput(sp, rd, wr)

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
          if File.exists?(get_task_name) # otherwise the task will be library anyway
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

    def add_grouping_tasks(library)
      namespace 'lib' do
        desc library
        task @name => library
      end
    end

    def get_temp_filename
      Dir.tmpdir + "/lake.tmp"
    end

    def no_sources_found()
    end

  end
end

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

  class Linkable < BuildingBlock
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

    def get_output_name(linker)
      prefix = get_output_prefix(linker)
      suffix = get_output_suffix(linker)
      return "#{prefix}#{name}#{suffix}"
    end
    def executable_name() # relative path
      return @exe_name if @exe_name

      parts = [@output_dir]

      if @output_dir_abs
        parts = [@output_dir_relPath] if @output_dir_relPath
        parts += additional_path_components()
      end
      linker = @tcs[:LINKER]
      parts << get_output_name(linker)

      @exe_name = File.join(parts)
      @exe_name
    end

    def get_task_name() # full path
      @project_dir + "/" + executable_name
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

    def deps
      if @deps == nil
        @deps = collect_dependencies
      end
      @deps
    end
    def cmd_lib_string(target_os)
      libraries=''
      deps.each do |d|
        if HasLibraries === d
          d.lib_elements.each do |elem|
            case elem[0]
            when HasLibraries::SEARCH_PATH
              tmp, prefix = adapt_path(elem[1], d, prefix)
              libraries << tmp
              libraries << @tcs[:ENV][:LIB_SEPARATOR][target_os]
            end
          end
        end
      end
      libraries
    end

    def linker_lib_string(target_os, linker)
      lib_path_set = Set.new
      res = []
      deps.each do |d|
        handle_whole_archive(d, res, linker, linker[:START_OF_WHOLE_ARCHIVE][target_os])
        if HasLibraries === d and d != self
          d.lib_elements.each do |elem|
            case elem[0]
            when HasLibraries::LIB
              if not is_whole_archive(d)
                res.push("#{linker[:LIB_FLAG]}#{elem[1]}")
              end
            when HasLibraries::USERLIB
              res.push("#{linker[:USER_LIB_FLAG]}#{elem[1]}") 
            when HasLibraries::LIB_WITH_PATH
              if is_whole_archive(d)
                res.push(d.get_archive_name)
              else
                tmp, prefix = adapt_path(elem[1], d, prefix)
                res.push(tmp)
              end
            when HasLibraries::SEARCH_PATH
              if is_whole_archive(d)
                res.push(d.get_archive_name)
              else
                tmp, prefix = adapt_path(elem[1], d, prefix)
                if not lib_path_set.include?(tmp)
                  lib_path_set << tmp
                  res.push("#{linker[:LIB_PATH_FLAG]}#{tmp}")
                end
              end
            end
          end
        end
        handle_whole_archive(d, res, linker, linker[:END_OF_WHOLE_ARCHIVE][target_os])
      end
      res
    end

    # res the array with command line arguments that is used as result
    # linker the linker hash
    # sym the symbol that is used to fish out a value from the linker
    def handle_whole_archive(building_block, res, linker, flag)
      if is_whole_archive(building_block)
        res.push(flag) if flag and !flag.empty?
      end
    end

    def is_whole_archive(building_block)
      return building_block.instance_of?(StaticLibrary) && building_block.whole_archive
    end

    def calc_command_line
      linker = @tcs[:LINKER]
      cmd = [linker[:COMMAND]] # g++
      cmd += linker[:MUST_FLAGS].split(" ")
      cmd += linker[:FLAGS]
      cmd += get_flags_for_output(linker)
      cmd << executable_name() # debug/x.exe
      cmd += @objects
      cmd << linker[:SCRIPT] if @linker_script # -T
      cmd << @linker_script if @linker_script # xy/xy.dld
      cmd << linker[:MAP_FILE_FLAG] if @mapfile # -Wl,-m6
      cmd += linker[:LIB_PREFIX_FLAGS].split(" ") # TODO ... is this still needed e.g. for diab
      cmd += linker_lib_string(target_os(), @tcs[:LINKER])
      cmd += linker[:LIB_POSTFIX_FLAGS].split(" ") # TODO ... is this still needed e.g. for diab
      cmd
    end

    # create a task that will link an executable from a set of object files
    #
    def convert_to_rake()
      object_multitask = prepare_tasks_for_objects()

      res = typed_file_task get_rake_task_type(), get_task_name => object_multitask do
        cmd = calc_command_line
        Dir.chdir(@project_dir) do
          mapfileStr = @mapfile ? " >#{@mapfile}" : ""
          rd, wr = IO.pipe
          cmdLinePrint = cmd
          printCmd(cmdLinePrint, "Linking #{executable_name}", false)
          cmd << {
            :out=> @mapfile ? "#{@mapfile}" : wr, # > xy.map
            :err=>wr
          }
          sp = spawn(*cmd)
          cmd.pop
          # for console print
          cmd << " >#{@mapfile}" if @mapfile
          consoleOutput = ProcessHelper.readOutput(sp, rd, wr)

          process_result(cmdLinePrint, consoleOutput, @tcs[:LINKER][:ERROR_PARSER], nil)
          check_config_file()
          post_link_hook(@tcs[:LINKER])
        end
      end
      res.tags = tags
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
              if bb and StaticLibrary === bb
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

    def create_run_task(executable, name)
      namespace 'run' do
        desc "run executable #{executable}"
        res = task name => executable do |t|
          lib_var = @tcs[:ENV][:LIB_VAR][@tcs[:TARGET_OS]]
          if lib_var != ''
            ENV[lib_var] = cmd_lib_string(@tcs[:TARGET_OS])
          end
          args = ENV['args'] ? ' ' + ENV['args'] : ''
          sh "\"#{executable}\"#{args}"
        end
        res.type = Rake::Task::RUN
        res
      end
    end

    def get_temp_filename
      Dir.tmpdir + "/lake.tmp"
    end

    def no_sources_found()
    end

    def target_os
      @tcs[:TARGET_OS]
    end
  end

  class Executable < Linkable
    def get_flags_for_output(linker)
      [linker[:OUTPUT_FLAG]]
    end
    def get_output_prefix(linker)
      ""
    end
    def get_output_suffix(linker)
      linker[:OUTPUT_SUFFIX][:EXECUTABLE][target_os]
    end
    def get_rake_task_type
      Rake::Task::EXECUTABLE
    end
    def additional_object_file_flags
      []
    end
    def add_grouping_tasks(executable)
      namespace 'exe' do
        desc executable
        task @name => executable
      end
      create_run_task(executable, @name)
    end

    def post_link_hook(linker)
    end
  end

  class SharedLibrary < Linkable
    
    attr_accessor :major
    attr_accessor :minor
    attr_accessor :compatibility
    
    def complete_init()
      if @output_dir_abs
        add_lib_element(HasLibraries::LIB, @name, true)
        add_lib_element(HasLibraries::SEARCH_PATH, File.join(@output_dir, 'libs'), true)
      else
        add_lib_element(HasLibraries::LIB_WITH_PATH, File.join(@output_dir,"lib#{@name}.a"), true)
      end
      super
    end


    def get_flags_for_output(linker)
      [linker[:SHARED_FLAG]] + additional_linker_commands(linker) + [linker[:OUTPUT_FLAG]]
    end
    def get_output_prefix(linker)
      linker[:OUTPUT_PREFIX][:SHARED_LIBRARY][target_os()]
    end

    def get_output_suffix(linker)
      h = linker[:ADDITIONAL_COMMANDS][target_os()]
      "#{(h ? h.get_version_suffix(linker, self) : "")}#{shared_suffix linker}"
    end
   
    def additional_path_components()
      ['libs']
    end
    def get_rake_task_type
      Rake::Task::SHARED_LIBRARY
    end
    def additional_object_file_flags
      linker = @tcs[:LINKER]
      linker[:ADDITIONAL_OBJECT_FILE_FLAGS][target_os()]
    end
    def add_grouping_tasks(shared_lib)
      namespace 'shared' do
        desc shared_lib
        task @name => shared_lib
      end
    end

    def shared_suffix(linker)
      linker[:OUTPUT_SUFFIX][:SHARED_LIBRARY][target_os()]
    end

    def post_link_hook(linker)
      linker = @tcs[:LINKER]
      os_linker_helper=linker[:ADDITIONAL_COMMANDS][target_os()]
      os_linker_helper.post_link_hook(linker, self)
    end
    private
    
    def additional_linker_commands(linker)
      h = linker[:ADDITIONAL_COMMANDS][target_os()]
      if h
        h.calc(linker, self)
      else
        []
      end
    end
  end
end

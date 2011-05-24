require 'cxxproject/buildingblocks/module'
require 'cxxproject/buildingblocks/makefile'
require 'cxxproject/buildingblocks/executable'
require 'cxxproject/buildingblocks/source_library'
require 'cxxproject/buildingblocks/single_source'
require 'cxxproject/buildingblocks/binary_library'
require 'cxxproject/buildingblocks/custom_building_block'
require 'cxxproject/buildingblocks/command_line'
require 'cxxproject/extensions/rake_ext'
require 'cxxproject/extensions/file_ext'
require 'cxxproject/utils/dot/graph_writer'

require 'logger'
require 'yaml'
require 'tmpdir'


# A class which encapsulates the generation of c/cpp artifacts like object-files, libraries and so on
class TaskMaker

  def initialize(logger)
    @log = logger
  end

  def set_loglevel(level)
    @log.level = level
  end

  def add_file_to_clean_task(name)
    CLEAN.include(name)
  end
  def add_task_to_clean_task(task)
    Rake.application["clean"].enhance([task])
  end
  def already_added_to_clean?(task)
    Rake.application["clean"].prerequisites.include?task
  end

  # this is the main api for the task_maker
  # it will create the tasks that are needed in order to create
  # one building block
  #
  # a building-block can be one of the following:
  # * a source-library-block (a static lib that will be created)
  # * an executable-block (which itself might need other libraries)
  # * a binary-library-block (for which we do not need to do anything since it is already done)
  # * a custom building block
  # * a compile-only source file block
  def create_tasks_for_building_block(bb)
    @log.debug "create tasks for: #{bb.name}"
    CLOBBER.include(bb.complete_output_dir)

    bb.calc_transitive_dependencies()

    res = nil
    if HasSources === bb
      res = create_tasks_for_buildingblock_with_sources(bb)
    else
      if (bb.instance_of?(BinaryLibrary)) then
        res = create_binary_lib_task(bb)
      elsif (bb.instance_of?(CustomBuildingBlock)) then
        res = create_custom_task(bb)
      elsif (bb.instance_of?(CommandLine)) then
        res = create_commandline_task(bb)
      elsif (bb.instance_of?(Makefile)) then
        res = create_makefile_task(bb)
      else
        raise 'unknown building block'
      end
    end

    init_show_in_graph_flags(bb)
    add_building_block_deps_as_prerequisites(bb,res)
    res
  end

  private

  def create_tasks_for_buildingblock_with_sources(bb)
    res = nil
    bb.calc_compiler_strings()
    object_tasks, objects_multitask = create_tasks_for_objects(bb)
    if (bb.instance_of?(SourceLibrary)) then
      res = create_source_lib(bb, object_tasks, objects_multitask)
    elsif (bb.instance_of?(Executable)) then
      res = create_exe_task(bb, object_tasks, objects_multitask)
    elsif (bb.instance_of?(SingleSource)) then
      res = create_single_source_task(bb, objects_multitask)
    elsif (bb.instance_of?(ModuleBuildingBlock)) then
      res = task bb.get_task_name
      res.transparent_timestamp = true
    end
    res
  end

  def create_custom_task(bb)
    desc bb.get_task_name
    task bb.get_task_name do
      bb.actions.each do |a|
        a.call
      end
    end
  end

  def create_binary_lib_task(bb)
    res = task bb.get_task_name
    def res.needed?
      return false
    end
    res.transparent_timestamp = true
    res
  end

  def init_show_in_graph_flags(bb)
    bb.config_files.each do |cf|
      # Rake.application[cf].showInGraph = GraphWriter::NO
    end
  end

  # convert building block deps to rake task prerequisites (e.g. exe needs lib)
  def add_building_block_deps_as_prerequisites(bb,res)
    bb.dependencies.reverse.each do |d|
      begin
        raise "ERROR: tried to add the dependencies of \"#{d}\" to \"#{bb.name}\" but such a building block could not be found!" unless ALL_BUILDING_BLOCKS[d]
        res.prerequisites.unshift(ALL_BUILDING_BLOCKS[d].get_task_name) 
      rescue Exception => e
        puts e
        exit
      end
    end
  end

  def create_single_source_task(bb, objects_multitask)
    res = nil
    if objects_multitask
      res = objects_multitask
      namespace "compile" do
        desc "compile sources in #{bb.name}-configuration"
        task bb.name => objects_multitask
      end
      objects_multitask.add_description("compile sources only")
    end
    res
  end

  def create_tasks_for_objects(bb)
    object_tasks = create_object_file_tasks(bb)
    objects_multitask = []
    if object_tasks.length > 0
      objects_multitask = multitask bb.get_sources_task_name => object_tasks
      def objects_multitask.needed?
        return false
      end
      objects_multitask.transparent_timestamp = true
    end
    [object_tasks,objects_multitask]
  end

  def convert_depfile(depfile, bb)
    deps = ""
    File.open(depfile, "r") do |infile|
      while (line = infile.gets)
        deps << line
      end
    end

    deps = deps.gsub(/\\\n/,'').split()[1..-1]
    deps.map!{|d| File.expand_path(d)}

    FileUtils.mkpath File.dirname(depfile)
    File.open(depfile, 'wb') do |f|
      f.write(deps.to_yaml)
    end
  end

  def create_apply_task(depfile,outfileTask,bb)
    res = task "#{depfile}.apply" do |task|
      deps = nil
      begin
        deps = YAML.load_file(depfile)
        outfileTask.enhance(deps)
      rescue
        # may happen if depfile was not converted the last time
        def outfileTask.needed?
          true
        end
      end
    end
    res.showInGraph = GraphWriter::NO
    res.transparent_timestamp = true
    res
  end

  def create_object_file_tasks(bb)
    tasks = []

    bb.sources.each do |s|
      type = bb.get_source_type(s)
      if type.nil?
        puts "Warning: no valid source type for #{File.relFromTo(s,bb.project_dir)}, will be ignored!"
        next
      end

      source = File.relFromTo(s,bb.project_dir)
      object = bb.get_object_file(s)
      depfile = bb.get_dep_file(object)

      if bb.tcs4source().include?s
        tcs = bb.tcs4source()[s]
        iString = bb.get_include_string(tcs, type)
        dString = bb.get_define_string(tcs, type)
      else
        tcs = bb.tcs
        iString = bb.include_string(type)
        dString = bb.define_string(type)
      end

      compiler = tcs[:COMPILER][type]
      depStr = type == :ASM ? "" : (compiler[:DEP_FLAGS] + depfile) # -MMD -MF debug/src/abc.o.d

      cmd = [compiler[:COMMAND], # g++
        compiler[:COMPILE_FLAGS], # -c
        depStr,
        compiler[:FLAGS], # -g3
        iString, # -I include
        dString, # -DDEBUG
        compiler[:OBJECT_FILE_FLAG], # -o
        object, # debug/src/abc.o
        source # src/abc.cpp
      ].reject{|e| e == ""}.join(" ")

      add_file_to_clean_task(depfile) if depStr != ""
      add_file_to_clean_task(object)

      outfileTask = file object => source do
        puts "compiling #{source}"
        puts `#{cmd + " 2>&1"}`
        convert_depfile(depfile, bb) if depStr != ""
        raise "System command failed" if $?.to_i != 0
        puts "ERROR with executing: #{cmd}" unless File.exists?object
      end
      outfileTask.showInGraph = GraphWriter::DETAIL
      outfileTask.enhance(bb.config_files)
      set_output_dir(object, outfileTask)
      outfileTask.enhance([create_apply_task(depfile,outfileTask,bb)]) if depStr != ""
      tasks << outfileTask
    end
    tasks
  end

  def create_commandline_task(bb)
  	res = task bb.get_task_name do
  	  cmd = bb.get_command_line
      puts cmd
      puts `#{cmd + " 2>&1"}`
      raise "System command failed" if $?.to_i != 0
  	end
  	res.transparent_timestamp = true
  	res
  end

  def create_makefile_task(bb)
    mfile = bb.get_makefile()
    cmd = [bb.tcs[:MAKE][:COMMAND], # make
      bb.get_target, # all
      bb.tcs[:MAKE][:MAKE_FLAGS], # ??
      bb.tcs[:MAKE][:FLAGS], # -j
      bb.tcs[:MAKE][:DIR_FLAG], # -C
      File.dirname(mfile), # x/y
      bb.tcs[:MAKE][:FILE_FLAG], # -f
      File.basename(mfile) # x/y/makefile
    ].reject{|e| e == ""}.join(" ")
    mfileTask = task bb.get_task_name do
      puts cmd
      puts `#{cmd + " 2>&1"}`
      raise "System command failed" if $?.to_i != 0
    end
    mfileTask.transparent_timestamp = true
    mfileTask.enhance(bb.config_files)

    # generate the clean task
    if not already_added_to_clean?(mfile+"Clean")
      cmdClean = [bb.tcs[:MAKE][:COMMAND], # make
        bb.tcs[:MAKE][:CLEAN], # clean
        bb.tcs[:MAKE][:DIR_FLAG], # -C
        File.dirname(mfile), # x/y
        bb.tcs[:MAKE][:FILE_FLAG], # -f
        File.basename(mfile) # x/y/makefile
      ].reject{|e| e == ""}.join(" ")
      mfileCleanTask = task mfile+"Clean" do
        puts cmdClean
        puts `#{cmdClean + " 2>&1"}`
        raise "System command failed" if $?.to_i != 0
      end
      add_task_to_clean_task(mfileCleanTask)
    end
    mfileTask
  end

  # task that will link the given object files to a static lib
  #
  def create_source_lib(bb, objects, object_multitask)
    archive = bb.get_archive_name()

    cmd = [bb.tcs[:ARCHIVER][:COMMAND], # ar
      bb.tcs[:ARCHIVER][:ARCHIVE_FLAGS], # -r
      bb.tcs[:ARCHIVER][:FLAGS], # ??
      archive, # debug/x.a
      objects.reject{|e| e == ""}.join(" ") # debug/src/abc.o debug/src/xy.o
    ].reject{|e| e == ""}.join(" ")

    res = file archive => object_multitask do
      puts cmd
      puts `#{cmd + " 2>&1"}`
      raise "System command failed" if $?.to_i != 0
    end
    add_file_to_clean_task(archive)
    res.enhance(bb.config_files)
    set_output_dir(archive, res)
    namespace 'lib' do
      desc archive
      task bb.name => archive
    end
    res
  end

  # create a task that will link an executable from a set of object files
  #
  def create_exe_task(bb, objects, object_multitask)
    executable = bb.get_executable_name()
    add_file_to_clean_task(executable)
    scriptFile = ""
    script = ""
    if bb.linker_script
      scriptFile = File.relFromTo(bb.linker_script, bb.project_dir)
      script = "#{bb.tcs[:LINKER][:SCRIPT]} #{scriptFile}"  # -T xy/xy.dld
    end

    mapfile = bb.mapfile ? "#{bb.tcs[:LINKER][:MAP_FILE_FLAG]} >#{File.relFromTo(bb.mapfile, bb.complete_output_dir)}" : "" # -Wl,-m6 > xy.map

    # calc linkerLibString (two steps for removing duplicates)
    lib_searchpaths_array = []
    libs_to_search_array = []
    user_libs_array = []
    libs_with_path_array = []
    deps = bb.all_dependencies
    deps.each do |e|
      d = ALL_BUILDING_BLOCKS[e]
      next if not HasLibraries === d
      d.lib_searchpaths.each { |k| lib_searchpaths_array << File.relFromTo(k, d.project_dir) }
      d.libs_to_search.each  { |k| libs_to_search_array  << k }
      d.user_libs.each       { |k| user_libs_array       << k }
      d.libs_with_path.each  { |k| libs_with_path_array  << File.relFromTo(k, d.project_dir) }
    end
    strArray = []
    lib_searchpaths_array.uniq.each { |k| strArray << "#{bb.tcs[:LINKER][:LIB_PATH_FLAG]}#{k}" }
    libs_to_search_array.uniq.each  { |k| strArray << "#{bb.tcs[:LINKER][:LIB_FLAG]}#{k}" }
    user_libs_array.uniq.each       { |k| strArray << "#{bb.tcs[:LINKER][:USER_LIB_FLAG]}#{k}" }
    libs_with_path_array.uniq.each  { |k| strArray << "#{k}" }
    linkerLibString = strArray.reject{|e| e == ""}.join(" ")

    cmd = [bb.tcs[:LINKER][:COMMAND], # g++
      bb.tcs[:LINKER][:MUST_FLAGS], # ??
      bb.tcs[:LINKER][:FLAGS], # --all_load
      bb.tcs[:LINKER][:EXE_FLAG], # -o
      executable, # debug/x.o
      objects.reject{|e| e == ""}.join(" "), # debug/src/abc.o debug/src/xy.o
      script,
      mapfile,
      bb.tcs[:LINKER][:LIB_PREFIX_FLAGS], # "-Wl,--whole-archive "
      linkerLibString,
      bb.tcs[:LINKER][:LIB_POSTFIX_FLAGS] # "-Wl,--no-whole-archive "
    ].reject{|e| e == ""}.join(" ")

    create_run_task(executable, bb.config_files, bb.name)

    res = file executable => object_multitask do
      # TempFile used, because some compilers, e.g. diab, uses ">" for piping to map files:
      puts cmd
      puts `#{cmd + " 2>" + get_temp_filename}`
      puts read_temp_file
      raise "System command failed" if $?.to_i != 0
    end
    res.enhance(bb.config_files)
    res.enhance([scriptFile]) unless scriptFile==""
    set_output_dir(executable, res)

    namespace 'exe' do
      desc executable
      task bb.name => executable
    end
    res
  end

  def create_run_task(executable, configFiles, name)
    namespace 'run' do
      desc "run executable #{executable}"
      task name => executable do
        sh "#{executable}"
      end
    end
  end

  def set_output_dir(file, taskOfFile)
    outputdir = File.dirname(file)
    directory outputdir
    taskOfFile.enhance([outputdir])
  end

  def get_temp_filename
    Dir.tmpdir + "/lake.tmp"
  end

  def read_temp_file
    lines = []
    File.open(get_temp_filename, "r") do |infile|
      while (line = infile.gets)
        lines << line
      end
    end
    lines
  end

end

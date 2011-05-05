<<<<<<< HEAD
require 'logger'
require 'benchmark'
# stores all rake tasks
ALL = FileList.new

# A class which encapsulates the generation of c/cpp artifacts like object-files, libraries and so on
class TaskMaker
  attr_reader :output_path

  # building_block_map is a mapping from unique names to building blocks
  def initialize(output_path, building_block_map, toolchain)
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
    @compiler = toolchain[:COMPILER][:CPP]
    @linker = toolchain[:LINKER]
    @deptool = toolchain[:DEPENDENCY]
    @output_path = output_path
    @includes = []
    CLOBBER.include(output_path)
    @defines = []
    @flags = []
    @linker_flags = []
    @building_block_map = building_block_map
    @benchmark = 0
  end
  def set_loglevel(level)
    @log.level = level
  end
  def register(name)
    CLEAN.include(name)
    ALL.include(name)
=======
require 'cxxproject/buildingblocks/module'
require 'cxxproject/buildingblocks/makefile'
require 'cxxproject/buildingblocks/executable'
require 'cxxproject/buildingblocks/source_library'
require 'cxxproject/buildingblocks/single_source'
require 'cxxproject/buildingblocks/binary_library'
require 'cxxproject/buildingblocks/custom_building_block'
require 'cxxproject/extensions/rake_ext'
require 'cxxproject/extensions/file_ext'

require 'logger'


# A class which encapsulates the generation of c/cpp artifacts like object-files, libraries and so on
class TaskMaker

  def initialize(logger)
    @log = logger
  end

  def set_loglevel(level)
    @log.level = level
  end

  def addFileToCleanTask(name)
    CLEAN.include(name)
  end
  def addTaskToCleanTask(task)
    Rake.application["clean"].enhance([task])
  end
  def taskAlreadyAddedToCleanTask(task)
    Rake.application["clean"].prerequisites.include?task
>>>>>>> apichange
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
<<<<<<< HEAD
  # 
  def create_tasks_for_building_blocks(building_block, project_configs, base)
    @log.debug "create_tasks_for_building_blocks: #{building_block}"
    if (building_block.instance_of?(SourceLibrary)) then
      build_source_lib_task(building_block, base)
    elsif (building_block.instance_of?(Exe)) then
      build_exe_task(building_block, project_configs, base)
    elsif (building_block.instance_of?(BinaryLibrary)) then
    elsif (building_block.instance_of?(CustomBuildingBlock)) then
    elsif (building_block.instance_of?(SingleSourceBlock)) then
      build_source_only_task(building_block, base)
    else
      raise 'unknown building_block'
    end
  end

  def build_source_only_task(lib, base)
    @log.debug "building sources only"
    object_tasks = lib.sources.map do |s|
      create_object_file_task(lib, s, base)
    end
    desc "compile sources only"
    multitask "multitask_#{lib.name}" => object_tasks
  end

  def build_source_lib_task(lib, base)
    @log.debug "building source lib"
    object_tasks = lib.sources.map do |s|
      create_object_file_task(lib, s, base)
    end
    t = multitask "multitask_#{lib}" => object_tasks
    create_source_lib(lib, object_tasks, t)
  end

  def build_exe_task(exe, project_configs, base)
    object_tasks = exe.sources.map do |s|
      create_object_file_task(exe, s, base)
    end
    t = multitask "multitask_#{exe}"  => object_tasks
    create_exe_task(exe, object_tasks, t, project_configs)
  end

  # a task will be created that can be used to compile a source file into an object file
  #
  # * first we determine all dependencies of the object-file
  # * then a file task is created that when executed compiles to the object file
  # * finally we add necessary dependencies to the object-creation-task and the
  #   dependency-calculation-task
  #
  def create_object_file_task(lib, relative_source, base)
    defines = get_defines
    source_path = File.join(lib.base, relative_source)
    out = output_filename(source_path, :object, base)
    outputdir = File.dirname(out)
    directory outputdir
    depfile = "#{out}.dependencies"
    depfile_task = file depfile => source_path do
      calc_dependencies(depfile, defines, include_string(lib),source_path)
    end
    command = [@compiler[:COMMAND],
               @compiler[:COMPILE_FLAGS],
               source_path,
               include_string(lib),
               defines,
               flags_string(@flags),
               @compiler[:OBJECT_FILE_FLAG]].join(' ')
    object_task = file out => depfile do |t|
      sh "#{command} #{t.name}"
    end
    idt = create_inject_include_dependencies_task(depfile, depfile_task, object_task)
    object_task.enhance([idt])
    depfile_task.enhance([outputdir])
    return object_task
  end

  # will result in a task that when executed will use the include-dependencies 
  # from the depfile and make the object-task depend on those include files
  # also the depfile-task itself will have to depend on those include files since
  # if any include file changes the include-dependencies will have to be re-calculated
  # 
  # * the depfile contains the transitive include dependencies (usually generated by compiler)
  # * the task that was used to create the defile in the first place (needs to depend itself on the includes)
  # * the object-task that will create the object file
  #
  def create_inject_include_dependencies_task(depfile, depfile_task, object_task)
    task "#{depfile}.apply" => depfile do |task|
      deps = YAML.load_file(depfile)
      if (deps)
        object_task.enhance(deps)
        depfile_task.enhance(deps[1..-1])
=======
  def create_tasks_for_building_block(bb, onlyFileDeps = false)
    @log.debug "create tasks for: #{bb.name}"

    CLOBBER.include(bb.output_dir)

    bb.calc_transitive_dependencies()

    if HasSources === bb
      bb.calc_compiler_strings()
      object_tasks = create_object_file_tasks(bb)
      t = multitask "multitask_#{bb.name}" => object_tasks
    end

    outputTaskname = task bb.name + " OUTPUTTASKNAME" do
      puts "**** Building: #{bb.name} ****"
    end

    res = nil
    if (bb.instance_of?(SourceLibrary)) then
      res = create_source_lib(bb, object_tasks, t)
      res.prerequisites.unshift(outputTaskname)
      res.showInGraph = GraphWriter::YES
    elsif (bb.instance_of?(Executable)) then
      res = create_exe_task(bb, object_tasks, t)
      res.prerequisites.unshift(outputTaskname)
      res.showInGraph = GraphWriter::YES
    elsif (bb.instance_of?(BinaryLibrary)) then
      # nothing?
    elsif (bb.instance_of?(CustomBuildingBlock)) then
      # todo...
      res.showInGraph = GraphWriter::YES
    elsif (bb.instance_of?(Makefile)) then
      res = create_makefile_task(bb)
      res.showInGraph = GraphWriter::YES
    elsif (bb.instance_of?(SingleSource)) then
      t.add_description("compile sources only")
      res = t
      res.showInGraph = GraphWriter::YES
    elsif (bb.instance_of?(ModuleBuildingBlock)) then
      res = task bb.get_task_name
      res.showInGraph = GraphWriter::HELPER
      res.transparent_timestamp = true
    else
      raise 'unknown building block'
    end

    bb.already_created = true
    
    bb.dependencies.each do |d|
      bbDep = ALL_BUILDING_BLOCKS[d]
      next if bbDep.instance_of?(BinaryLibrary)
      tname = bbDep.get_task_name
      next if onlyFileDeps and not File.exist?(tname) # used for build project only
      res.enhance([tname])
      # TODO handle circular dependencies
    end
        
    res

  end

  private

  def convertDepfile(depfile, bb)
    deps = ""
    File.open(depfile, "r") do |infile|
      while (line = infile.gets)
        deps << line
      end
    end

    deps = deps.gsub(/\\\n/,'').split()[1..-1]
    #todo: kann weg? Rake.application["#{depfile}.apply"].deps = deps.clone() # = no need to re-read the deps file
    deps.map!{|d| File.relFromTo(d,::Dir.pwd,bb.project_dir)}

    FileUtils.mkpath File.dirname(depfile)
    File.open(depfile, 'wb') do |f|
      f.write(deps.to_yaml)
    end
  end

  def create_apply_task(depfile,outfileTask,bb)
    task "#{depfile}.apply" do |task|
      deps = nil
      if File.exists? depfile
        begin
          deps = YAML.load_file(depfile)
          deps.map!{|d| File.relFromTo(d,bb.project_dir)} if deps
        rescue
          # may happen if depfile was not converted the last time
        end
      end
      if (deps)
        outfileTask.enhance(deps)
      else
        def outfileTask.needed?
          true
        end
>>>>>>> apichange
      end
    end
  end

<<<<<<< HEAD
  # task that will create the include-dependencies-file using the compilers
  # include-dependencies-checker
  #
  def calc_dependencies(depFile, define_string, include_string, source)
    @log.info "calc_dependencies for #{depFile}"
    command = [@deptool[:COMMAND],
               @deptool[:FLAGS],
               define_string,
               include_string,
               source].join(' ')
    deps = nil
    @benchmark = @benchmark + Benchmark.realtime do
      deps = `#{command}`
    end
    @log.debug "overall dependency calculation so far took: " + sprintf("%.5f", @benchmark) + " second(s)."
    @log.debug "deps were: #{deps}, writing out to yaml file #{depFile}"
    if deps.length == 0
      raise 'cannot calc dependencies'
    end
    deps = deps.gsub(/\\\n/,'').split()[1..-1]
    File.open(depFile, 'wb') do |f|
      f.write(deps.to_yaml)
    end
=======


  def create_object_file_tasks(bb)
    tasks = []

    bb.sources.each do |s|
      type = bb.getSourceType(s)
      if type.nil?
        next
      end

      source = File.relFromTo(s,bb.project_dir)
      object = bb.get_object_file(source)
      depfile = bb.get_dep_file(object)

      outputdir = File.dirname(object)
      directory  outputdir

      cmd = [bb.tcs[:COMPILER][type][:COMMAND], # g++
        bb.tcs[:COMPILER][type][:COMPILE_FLAGS], # -c
        bb.tcs[:COMPILER][type][:DEP_FLAGS], # -MMD -MF
        depfile, # debug/src/abc.o.d
        bb.tcs[:COMPILER][type][:FLAGS], # -g3
        source, # src/abc.cpp
        bb.includeString(type), # -I include
        bb.defineString(type), # -DDEBUG
        bb.tcs[:COMPILER][type][:OBJECT_FILE_FLAG], # -o
        object # debug/src/abc.o
      ].join(" ")

      addFileToCleanTask(depfile)
      addFileToCleanTask(object)

      outfileTask = file object do
        sh cmd
        convertDepfile(depfile, bb)
      end
      outfileTask.showInGraph = GraphWriter::OBJ
      outfileTask.enhance(bb.config_files)
      outfileTask.enhance([outputdir])
      outfileTask.enhance([create_apply_task(depfile,outfileTask,bb)])

      tasks << outfileTask

    end

    tasks

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
      File.basename(mfile) # x/y/makfile
    ].join(" ")
    mfileTask = task bb.get_task_name do
      sh cmd
    end
    mfileTask.transparent_timestamp = true
    mfileTask.enhance(bb.configFiles)

    # generate the clean task
    if not taskAlreadyAddedToCleanTask(mfile+"Clean")
      cmdClean = [bb.tcs[:MAKE][:COMMAND], # make
        bb.tcs[:MAKE][:CLEAN], # clean
        bb.tcs[:MAKE][:DIR_FLAG], # -C
        File.dirname(mfile), # x/y
        bb.tcs[:MAKE][:FILE_FLAG], # -f
        File.basename(mfile) # x/y/makfile
      ].join(" ")
      mfileCleanTask = task mfile+"Clean" do
        sh cmdClean
      end
      addTaskToCleanTask(mfileCleanTask)
    end
    mfileTask

>>>>>>> apichange
  end

  # task that will link the given object files to a static lib
  #
<<<<<<< HEAD
  def create_source_lib(lib, object_tasks, object_multitask)
    fullpath = static_lib_path(lib.name)
    @log.info "create source lib:#{fullpath}"
    command = object_tasks.inject("ar -r #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    @log.debug "command will be: #{command}"
    register(fullpath)
    deps = [object_multitask].dup
    deps += lib.dependencies.map {|dep|get_path_for_lib(dep)}.flatten
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      @log.info "\nlink #{lib.name}\n"
      sh command
    end
    res
  end

  LibPrefix='-Wl,--whole-archive'
  LibPostfix='-Wl,--no-whole-archive'

  # create a task that will link an executable from a set of object files
  #
  def create_exe_task(exe, object_tasks, object_multitask, project_configs)
    exename = "#{exe.name}.exe"
    fullpath = File.join(@output_path, exename)
    base_command = [@linker[:COMMAND], @linker[:FLAGS], @linker[:EXE_FLAG], fullpath].join(' ')
    command = object_tasks.inject(base_command) do |command, o|
      "#{command} #{o}"
    end
    dep_paths = exe.dependencies.map {|dep|get_path_for_lib(dep)}.flatten
    register(fullpath)
    deps = [object_multitask].dup
    deps += dep_paths
    executableName = File.basename(exe.name)
    desc "link executable #{executableName}"
    task executableName.to_sym => fullpath
    res = file fullpath => deps + project_configs do
      command += " #{LibPrefix} " if OS.linux?
      command = transitive_libs(exe).inject(command) {|command,l|"#{command} #{l}"}
      command += " #{LibPostfix}" if OS.linux?
      sh command
    end
    create_run_task(fullpath, project_configs)
    return res
  end
  
  def create_run_task(p, project_configs)
    desc "run executable"
    task :run => project_configs << p do
      sh "#{p}"
    end
  end

  #
  # all methods from here on are only helper methods
  #

  def get_libendings_defaults
    return ["a","dylib"]
  end

  def get_libendings(lib)
    # TODO: do we need the config here?
    # return lib.config.get_value(:lib_endings) || get_libendings_defaults
    return get_libendings_defaults
  end

  def binary_lib_path(lib)
    possibilities = get_libendings(lib).inject([]) { |res, ending| get_paths(lib).inject(res) { |res, lib_path| res << File.join(lib_path, 'lib', "lib#{lib.name}.#{ending}") } }
    i = possibilities.index{ |x| File.exists?(x)}
    if i
      possibilities[i]
    else
      raise "could not find libpath for #{lib.name}"
    end
  end

  def static_lib_path(name)
    libname = "lib#{name}.a"
    fullpath = File.join(@output_path, libname)
    return fullpath
  end

  def get_path_for_lib(d)
    lib = @building_block_map[d]
    if !lib
      raise "could not find library with name '#{d}'"
    end
    if (lib.instance_of?(BinaryLibrary))
      binary_lib_path(lib)
    else
      static_lib_path(lib.name)
    end
  end

  def get_path_defaults
    return ["/usr/local", "/usr", "/opt/local", "C:/cygwin", "C:/tool/cygwin"]
  end

  def get_paths(lib)
    # TODO: do we need the config here?
    # paths = lib.config.get_value(:binary_paths) || get_path_defaults
    paths = get_path_defaults
  end

  def transitive_includes(lib)
    res = Dependencies.transitive_dependencies([lib.name]).inject([]) do |res, i|
      if (i.instance_of?(BinaryLibrary))
        if i.includes
          res << i.includes
        else
          res << get_paths(lib).map{ |path| File.join(path, 'include') }
        end
      else
        if i.includes
          res << i.includes.map { |include| Pathname.new(File.join(i.base, include)).cleanpath.to_s }
        end
      end
      res
    end
    res += @includes
    return res.flatten.delete_if{|i|i.size == 0}
  end

  def transitive_libs(from)
    res = Dependencies.transitive_dependencies([from.name]).delete_if{|i|i.instance_of?(Exe)}.map do |i|
      if (i.instance_of?(BinaryLibrary))
        path = binary_lib_path(i)
        "#{@linker[:LIB_PATH_FLAG]}#{File.dirname(path)} #{@linker[:LIB_FLAG]}#{i.name}"
      else
        "#{@output_path}/lib#{i.name}.a"
      end
    end
    return res
  end

  def include_string(d)
    includes = transitive_includes(d).uniq
    @log.debug "------------> #{includes}"
    includes.inject('') { | res, i | "#{res} #{@compiler[:INCLUDE_PATH_FLAG]}#{i} " }
  end

  def flags_string(flags)
    flags.map{ |f| "-#{f}"}.join(' ')
  end
  def get_linker_flags
    @linker_flags.map{ |f| "-#{f}"}.join(' ')
  end
  def get_defines
    @defines.map{ |i| "#{@compiler[:DEFINE_FLAG]}#{i}"}.join(' ')
  end
  def type_to_path(type)
    return "#{type.to_s}s"
  end

  def type_to_ending(type)
    case type
      when :object
        return 'o'
      else
        raise "Unknown type: #{type}"
    end
  end

  def output_filename(source, type, base)
    File.join(@output_path, type_to_path(type), "#{source.remove_from_start(base)}.#{type_to_ending(type)}")
  end
=======
  def create_source_lib(bb, objects, object_multitask)
    archive = bb.get_archive_name()
    @log.debug "creating #{archive}"

    cmd = [bb.tcs[:ARCHIVER][:COMMAND], # ar
      bb.tcs[:ARCHIVER][:ARCHIVE_FLAGS], # -r
      bb.tcs[:ARCHIVER][:FLAGS], # ??
      archive, # debug/x.a
      objects.join(" ") # debug/src/abc.o debug/src/xy.o
    ].join(" ")
    desc "build lib"
    res = file archive => object_multitask do
      sh cmd
    end
    addFileToCleanTask(archive)
    res.enhance(bb.config_files)
    res
  end



  # create a task that will link an executable from a set of object files
  #
  def create_exe_task(bb, objects, object_multitask)
    executable = bb.get_executable_name()

    @log.debug "creating #{executable}"

    addFileToCleanTask(executable)

    script = bb.linker_script ? "#{bb.tcs[:LINKER][:SCRIPT]} #{File.relFromTo(bb.linker_script, bb.project_dir)}" : "" # -T xy/xy.dld
    mapfile = bb.mapfile ?  "#{bb.tcs[:LINKER][:MAP_FILE_FLAG]} > #{File.relFromTo(bb.mapfile, bb.project_dir)}" : "" # -Wl,-m6 > xy.map

    strMap = []
    deps = bb.all_dependencies
    deps.each do |e|
      d = ALL_BUILDING_BLOCKS[e]
      next if not HasLibraries === d
      d.lib_searchpaths.each { |k| strMap  << "#{bb.tcs[:LINKER][:LIB_PATH_FLAG]}#{File.relFromTo(k, d.project_dir)}" }
      d.libs_to_search.each  { |k| strMap  << "#{bb.tcs[:LINKER][:LIB_FLAG]}#{k}" }
      d.user_libs.each       { |k| strMap  << "#{bb.tcs[:LINKER][:USER_LIB_FLAG]}#{k}" }
      d.get_libs_with_path.each  { |k| strMap << File.relFromTo(k, d.project_dir) }
    end
    linkerLibString = strMap.join(" ")

    cmd = [bb.tcs[:LINKER][:COMMAND], # g++
      bb.tcs[:LINKER][:MUST_FLAGS], # ??
      bb.tcs[:LINKER][:FLAGS], # --all_load

      bb.tcs[:LINKER][:EXE_FLAG], # -o
      executable, # debug/x.o

      objects.join(" "), # debug/src/abc.o debug/src/xy.o

      script,
      mapfile,
      bb.tcs[:LINKER][:LIB_PREFIX_FLAGS], # "-Wl,--whole-archive "
      linkerLibString,
      bb.tcs[:LINKER][:LIB_POSTFIX_FLAGS] # "-Wl,--no-whole-archive "
    ].join(" ")


    res = file executable => object_multitask do
      sh cmd
    end
    res.enhance(bb.config_files)
    res.enhance([script]) unless script==""

    create_run_task(executable, bb.config_files)
    res
  end

  def create_run_task(executable, configFiles)
    desc "run executable"
    task :run => executable do
      sh "#{executable}"
    end
  end

>>>>>>> apichange
end

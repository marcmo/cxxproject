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
      end
    end
  end



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

  end

  # task that will link the given object files to a static lib
  #
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

end

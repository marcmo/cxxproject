require 'yaml'
require 'cxxproject/toolchain/settings'
require 'cxxproject/rake_ext'

class TaskMaker
  attr_reader :makefileCleaner

  def initialize()
    @makefileCleaner = task "makefileCleaner"
    @depSum = 0
    @depCounter = 0
  end

  def addToCleanTask(name)
    CLEAN.include(name)
  end

  def calcSourceDeps(depfile, sourceFull, settings, type)
    command = "g++ -MM #{settings.definesString[type]} #{settings.includeDirsString[type]} #{sourceFull}"
    p command
    deps = `#{command}`

    if deps.length == 0
      raise "cannot calc dependencies of #{sourceFull}"
    end

    deps = deps.gsub(/\\\n/,'').split()[1..-1]

    Rake.application["#{depfile}.apply"].deps = deps.clone() # = no need to re-read the deps file

    deps.map!{|d| File.relFromTo(d,::Dir.pwd,settings.config.getProjectDir)}
    FileUtils.mkpath File.dirname(depfile)
    File.open(depfile, 'wb') do |f|
      f.write(deps.to_yaml)
    end
  end


  def create_apply_task(depfile,depfileTask,outfileTask,settings)
    task "#{depfile}.apply" => depfile do |task|
      deps = task.deps
      if not deps
        deps = YAML.load_file(depfile)
        deps.map!{|d| File.relFromTo(d,settings.config.getProjectDir)}
      end
      if (deps)
        outfileTask.enhance(deps) # needed if makefiles change sth after depTask
        depfileTask.enhance(deps[1..-1])
      end
    end
  end

  def create_object_file_task(source, settings)
    type = settings.getSourceType(source)
    if type.nil?
      return nil
    end

    source = File.relFromTo(source,settings.config.getProjectDir)
    object = settings.getObjectName(source)

    outputdir = settings.getOutputDir()
    directory outputdir

    depfile = "#{object}.d"

    addToCleanTask(depfile)
    addToCleanTask(object)

    depfileTask = file depfile => source do
      calcSourceDeps(depfile, source, settings, type)
    end
    depfileTask.showInGraph = true

    cmd = "#{settings.toolchainSettings[:COMPILER][type][:COMMAND]} " + # g++
    "#{settings.toolchainSettings[:COMPILER][type][:COMPILE_FLAGS]} " + # -c
    "#{settings.toolchainSettings[:COMPILER][type][:FLAGS]} " + # -g3
    "#{source} " + # src/abc.cpp
    "#{settings.includeDirsString[type]} " + # -I include
    "#{settings.definesString[type]} " + # -DDEBUG
    "#{settings.toolchainSettings[:COMPILER][type][:OBJECT_FILE_FLAG]} " + # -o
    "#{object} " # debug/src/abc.o

    outfileTask = file object => depfileTask do |t|
      sh cmd
    end
    outfileTask.showInGraph = true

    outfileTask.enhance([create_apply_task(depfile,depfileTask,outfileTask,settings)])

    depfileTask.enhance([outputdir])

    outfileTask.enhance(settings.configFiles)
    depfileTask.enhance(settings.configFiles)

    return outfileTask
  end


  def create_makefile_tasks(settings,type)
    tasks = []
    settings.makefiles[type].each do |m|
      t = task m[:FILENAME] +" Build" do |x|
      
        sh "#{settings.toolchainSettings[:MAKE][:COMMAND]} " + # make
		  "#{m[:TARGET]} " + # all
		  "#{settings.toolchainSettings[:MAKE][:MAKE_FLAGS]} " + # ??
		  "#{settings.toolchainSettings[:MAKE][:FLAGS]} " + # -j
		  "#{settings.toolchainSettings[:MAKE][:DIR_FLAG]} " + # -C
		  "#{File.dirname(m[:FILENAME])} " + # x/y
		  "#{settings.toolchainSettings[:MAKE][:FILE_FLAG]} " + # -f
		  "#{File.basename(m[:FILENAME])}" # x/y/makfile
        
      end  
        
      tasks << t
      t.showInGraph = true
    end
    return tasks if tasks.length > 0
    return nil
  end


  def create_makefile_clean_tasks(settings)
    tasks = []
    (settings.makefiles[:BEGIN]+settings.makefiles[:MID]+settings.makefiles[:END]).each do |m|
      t = task m[:FILENAME]+" Clean" do |x|
        sh "#{settings.toolchainSettings[:MAKE][:COMMAND]} " + # make
        "#{settings.toolchainSettings[:MAKE][:CLEAN]} " + # clean
        "#{settings.toolchainSettings[:MAKE][:DIR_FLAG]} " + # -C
        "#{File.dirname(m[:FILENAME])} " + # x/y
        "#{settings.toolchainSettings[:MAKE][:FILE_FLAG]} " + # -f
        "#{File.basename(m[:FILENAME])}" # x/y/makfile
      end
      tasks << t
    end
    return tasks if tasks.length > 0
    return nil
  end


  # sequence of prerequisites is important, do not use drake!
  def create_project_task(settings, deps = nil)
    t = create_exe_task_internal(settings) if settings.type == :Executable
    t = create_archive_task_internal(settings) if settings.type == :Library
    t = task settings.name+" Custom" unless t

    t.showInGraph = true
    addToCleanTask settings.getOutputDir()
    t.enhance(settings.configFiles)

    outputdir = settings.getOutputDir()
    directory outputdir
    t.enhance([outputdir])

    if deps
      deps.each do |d|
        t.enhance([create_project_task(d)])
      end
      @depSum = deps.length + 1
    end
    

	outputTaskname = task settings.name+ " OUTPUTTASKNAME" do
		@depCounter = @depCounter + 1
		puts "**** Building: #{settings.name} (#{@depCounter} of #{@depSum}) ****"
	end
	 
   	t.enhance([outputTaskname])
    
    # makefile clean
    @makefileCleaner.enhance(create_makefile_clean_tasks(settings))

    # makefile begin
    mkBegin = create_makefile_tasks(settings,:BEGIN)
    t.enhance(mkBegin) if mkBegin

    # objects
    multi = multitask settings.name + " Parallel"
    multi.showInGraph = true
    settings.sources.each do |s|
      objecttask = create_object_file_task(s,settings)
      if objecttask.nil?
        # todo: log error
        next
      end
      multi.enhance([objecttask])
    end
    t.enhance([multi]) if multi.prerequisites.length > 0

    # makefile mid
    mkMid = create_makefile_tasks(settings,:MID)
    t.enhance(mkMid) if mkMid

    # makefile end
    mkEnd = create_makefile_tasks(settings,:END)
    if mkEnd != nil
      mkEnd.each do |mfTask|
        mfTask.enhance([t])
      end
      if mkEnd.length==1
        return mkEnd[0]
      else # we need a dummy task
        allMkEnd = task settings.config.name+" Make After Link" => mkEnd
        return allMkEnd
      end
    end
    return t
  end


  def create_archive_task_internal(settings)
    archive = settings.getArchiveName()
    addToCleanTask(archive)

    res = file archive do
      sh "#{settings.toolchainSettings[:ARCHIVER][:COMMAND]} " + # ar
      "#{settings.toolchainSettings[:ARCHIVER][:ARCHIVE_FLAGS]} " + # -r
      "#{settings.toolchainSettings[:ARCHIVER][:FLAGS]} " + # ??
      "#{archive} " + # debug/x.a
      "#{settings.sources.map{|s| settings.getObjectName(s)}.join(" ")}" # debug/src/abc.o debug/src/xy.o
    end

    res.showInGraph = true
    return res
  end



  def create_exe_task_internal(settings)
    executable = settings.getExecutableName()
    addToCleanTask(executable)

    userLibs = settings.userLibs.map! {|k| "#{settings.toolchainSettings[:LINKER][:USER_LIB_FLAG]}#{k}" }.join(" ")
    libs = settings.libs.map! {|k| "#{settings.toolchainSettings[:LINKER][:LIB_FLAG]}#{k}" }.join(" ")
    libPaths = settings.libPaths.map! {|k| "#{settings.toolchainSettings[:LINKER][:LIB_PATH_FLAG]}#{k}" }.join(" ")
    libsWithPath = settings.libsWithPath.join(" ")

    script = settings.linkerScript != "" ? "#{settings.toolchainSettings[:LINKER][:SCRIPT]} #{settings.linkerScript}" : "" # -T xy/xy.dld
    mapfile = settings.getMapfileName != "" ?  "#{settings.toolchainSettings[:LINKER][:MAP_FILE_FLAG]} > #{settings.getMapfileName}" : "" # -Wl,-m6 > xy.map

    res = file executable do
      sh "#{settings.toolchainSettings[:LINKER][:COMMAND]} " + # g++
      "#{settings.toolchainSettings[:LINKER][:MUST_FLAGS]} " + # ??
      "#{settings.toolchainSettings[:LINKER][:FLAGS]} " + # --all_load

      "#{settings.toolchainSettings[:LINKER][:EXE_FLAG]} " + # -o
      "#{executable} " + # debug/x.o

      "#{settings.sources.map{|s| settings.getObjectName(s)}.join(" ")} " + # debug/src/abc.o

      "#{script} " +
      
      "#{mapfile} " +

      "#{libPaths} " +

      "#{settings.toolchainSettings[:LINKER][:LIB_PREFIX_FLAGS]} " + # "-Wl,--whole-archive "
      "#{libsWithPath} " +
      "#{userLibs} " +
      "#{libs} " +
      "#{settings.toolchainSettings[:LINKER][:LIB_POSTFIX_FLAGS]} " # "-Wl,--no-whole-archive "
    end

    res.enhance([script]) if script != ""

	res.linkTask = true
    res.showInGraph = true
    return res
  end


  # todo: dylib als lib endung?


end

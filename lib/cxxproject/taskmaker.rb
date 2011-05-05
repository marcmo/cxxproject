require 'yaml'
require 'cxxproject/toolchain/settings'
require 'cxxproject/rake_ext'

class TaskMaker
  attr_reader :makefileCleaner

  def initialize()
    @makefileCleaner = task "makefileCleaner"
    @depSum = 1
    @depCounter = 0
  end

  def addToCleanTask(name)
    CLEAN.include(name)
  end

  def writeDepfile(deps, depfile, settings)
    deps = deps.gsub(/\\\n/,'').split()[1..-1]
    Rake.application["#{depfile}.apply"].deps = deps.clone() # = no need to re-read the deps file

    deps.map!{|d| File.relFromTo(d,::Dir.pwd,settings.config.getProjectDir)}
    FileUtils.mkpath File.dirname(depfile)
    File.open(depfile, 'wb') do |f|
      f.write(deps.to_yaml)
    end
  end

  def create_apply_task(depfile,outfileTask,settings)
    task "#{depfile}.apply" do |task|
      deps = task.deps
      if not deps and File.exists? depfile
      	begin
        	deps = YAML.load_file(depfile)
        	deps.map!{|d| File.relFromTo(d,settings.config.getProjectDir)} if deps
        rescue
        	deps = nil # may happen if depfile was not converted the last time
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


  def create_object_file_task(source, settings)
    type = settings.getSourceType(source)
    if type.nil?
      return nil
    end

    source = File.relFromTo(source,settings.config.getProjectDir)
    object = settings.getObjectName(source)

    outputdir = File.dirname(object)
    directory  outputdir

    depfile = settings.getDepfileName(object)

    cmd = "#{settings.toolchainSettings[:COMPILER][type][:COMMAND]} " + # g++
    "#{settings.toolchainSettings[:COMPILER][type][:COMPILE_FLAGS]} " + # -c
    "#{settings.toolchainSettings[:COMPILER][type][:FLAGS]} " + # -g3
    "#{source} " + # src/abc.cpp
    "#{settings.includeDirsString[type]} " + # -I include
    "#{settings.definesString[type]} " + # -DDEBUG
    "#{settings.toolchainSettings[:COMPILER][type][:OBJECT_FILE_FLAG]} " + # -o
    "#{object} " # debug/src/abc.o

    addToCleanTask(depfile)
    addToCleanTask(object)

    outfileTask = file object do
      sh cmd
      if settings.toolchainSettings[:DEP_BY_GCC] == false
        deps = ""
        File.open(depfile, "r") do |infile|
          while (line = infile.gets)
            deps << line
          end
        end
        writeDepfile(deps, depfile, settings)
      end
    end
    outfileTask.showInGraph = true
    outfileTask.enhance(settings.configFiles)
    outfileTask.enhance([outputdir])
    
    if not File.exists? depfile
      def outfileTask.needed? 
        true
      end
    end

    applyTask = create_apply_task(depfile,outfileTask,settings)

    if settings.toolchainSettings[:DEP_BY_GCC] == true
      depfileTask = file depfile => source do
	    command = "g++ -MM #{settings.definesString[type]} #{settings.includeDirsString[type]} #{source}"
	    puts command
	    Thread.current[:stdout].syncFlush if Thread.current[:stdout] # nicer output if command raises an exception
	    deps = `#{command}`
	    raise "cannot calc dependencies of #{source}" if deps.length == 0
		writeDepfile(deps, depfile, settings)        
      end
      depfileTask.showInGraph = true
      depfileTask.enhance([outputdir])
      depfileTask.enhance(settings.configFiles)

      outfileTask.enhance([depfileTask])
	  applyTask.enhance([depfile])
    end

    outfileTask.enhance([applyTask]) # must be after outfileTask.enhance([depfileTask])

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
      def t.timestamp 
        Rake::EARLY # makefiles do not trigger other tasks to run (at least directly...)
      end
      tasks << t
      t.showInGraph = true
    end
    tasks
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
    tasks
  end


  # sequence of prerequisites is important, do not use drake!
  def create_project_task(settings, deps = nil)
  	
  	rootTask = task "Root task based on "+settings.name
    if deps
      deps.each do |d|
        rootTask.enhance([create_project_task(d)])
      end
      @depSum = deps.length + 1
    end
  
    t = create_exe_task_internal(settings) if settings.type == :Executable
    t = create_archive_task_internal(settings) if settings.type == :Library
    t = task settings.name+" Custom" unless t

    t.showInGraph = true
    addToCleanTask settings.getOutputDir()
    t.enhance(settings.configFiles)

    outputdir = settings.getOutputDir()
    directory outputdir
    t.enhance([outputdir])



    outputTaskname = task settings.name+ " OUTPUTTASKNAME" do
      @depCounter = @depCounter + 1
      puts "**** Building: #{settings.name} (#{@depCounter} of #{@depSum}) ****"
    end

    t.enhance([outputTaskname])

    # makefile clean
    @makefileCleaner.enhance(create_makefile_clean_tasks(settings))

    # makefile begin
    t.enhance(create_makefile_tasks(settings,:BEGIN))

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
    t.enhance(create_makefile_tasks(settings,:MID))

    # makefile end
    mkEnd = create_makefile_tasks(settings,:END)
    if mkEnd.length > 0
	    mkEnd.each do |mfTask|
	      mfTask.enhance([t])
	    end
	    if mkEnd.length==1
	      rootTask.enhance(mkEnd[0])
	    else # we need a dummy task
	      allMkEnd = task settings.config.name+" Make After Link" => mkEnd
	      rootTask.enhance([allMkEnd])
	    end
	else
    	rootTask.enhance([t])
    end
    return rootTask
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

    res.enhance(settings.libsWithPath) # todo test: are that tasks???
    res.enhance([script])

    res.showInGraph = true
    return res
  end


  # todo: dylib als lib endung?


end

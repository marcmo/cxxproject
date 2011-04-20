# TODO:
# command hook pre post build
# build webserver resources
# clean von subprojekten?? (dirs)
# .cpp.o .c.o statt .o
# wann der prefix postfix??? --> oliver

#  def get_path_defaults
#    return ["/usr/local", "/usr", "/opt/local", "C:/cygwin", "C:/tool/cygwin"]
#  end

require 'yaml'
require 'cxxproject/toolchain/settings'

# A class which encapsulates the generation of c/cpp artifacts like object-files, libraries and so on
# perhaps this should be reworked to toolchain with compiler, linker, ...

$SourceToBuild = ""

class TaskMaker
  attr_reader :makefileCleaner
  
  def initialize()
  	@makefileCleaner = task "makefileCleaner" do |t|
  	end
  end
  
  def register(name)
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
    deps.map!{|d| makeFilename(d,::Dir.pwd,settings.config.getProjectDir)}
    FileUtils.mkpath File.dirname(depfile)
    File.open(depfile, 'wb') do |f|
      f.write(deps.to_yaml)
    end
  end
  
  
  def create_apply_task(depfile,depfileTask,outfileTask,settings)
    task "#{depfile}.apply" => depfile do |task|
      deps = YAML.load_file(depfile)
      if (deps)
        #outfileTask.enhance(settings.projectDir + "/" + deps)
        #depfileTask.enhance(deps[1..-1].map{|k| settings.projectDir + "/" + k})
        #warn "----"
        #warn settings.config.getProjectDir
        #warn outfileTask
        #warn depfileTask
        #warn depfile
        #warn deps
        
        deps.map!{|d| makeFilename(d,settings.config.getProjectDir)}
        
        #warn "!!!!"
        #warn deps
        
        
        outfileTask.enhance(deps)
        depfileTask.enhance(deps[1..-1])
      end
    end
  end

  # source must be relative to settings.projectDir - todo:really? 
  def create_object_file_task(source, settings)
  	type = settings.getSourceType(source)
  	if type.nil?
  		return nil
  	end
  	
  	source = makeFilename(source,settings.config.getProjectDir)
  	object = settings.getObjectName(source)
    outputdir = settings.getOutputDir()
    directory outputdir
    register(outputdir)
    #register outputdirFull todo in build lib!  ??
    
    depfile = "#{object}.d"
    register(depfile)
    
    depfileTask = file depfile => source do
      calcSourceDeps(depfile, source, settings, type)
    end
    
    cmd = "#{settings.toolchainSettings[:COMPILER][type][:COMMAND]} " + # g++
      	 "#{settings.toolchainSettings[:COMPILER][type][:COMPILE_FLAGS]} " + # -c
      	 "#{settings.toolchainSettings[:COMPILER][type][:FLAGS]} " + # -g3
      	 "#{source} " + # src/abc.cpp 
      	 "#{settings.includeDirsString[type]} " + # -I include
      	 "#{settings.definesString[type]} " + # -DDEBUG
      	 "#{settings.toolchainSettings[:COMPILER][type][:OBJECT_FILE_FLAG]} " + # -o
      	 "#{object} " # debug/src/abc.o
    
    outfileTask = file object => depfile do |t|
    	sh cmd
    end
    outfileTask.enhance([create_apply_task(depfile,depfileTask,outfileTask,settings)])
    depfileTask.enhance([outputdir])
    return outfileTask
  end


  def create_makefile_task(settings)
    makefileTask = task settings.makefile do |t|
      sh "#{settings.toolchainSettings[:MAKE][:COMMAND]} " + # make
      	 "#{settings.toolchainSettings[:MAKE][:MAKE_FLAGS]} " + # ??
      	 "#{settings.toolchainSettings[:MAKE][:FLAGS]} " + # -j
      	 "#{settings.toolchainSettings[:MAKE][:FILE_FLAG]} " + # -f
      	 "#{settings.makefile}" # x/makfile
    end
    return makefileTask
  end

  def create_makefile_clean_task(settings)
    makefileCleanTask = task settings.makefile+"clean" do |t|
      sh "#{settings.toolchainSettings[:MAKE][:COMMAND]} " + # make
      	 "#{settings.toolchainSettings[:MAKE][:CLEAN]} " + # clean
      	 "#{settings.toolchainSettings[:MAKE][:FILE_FLAG]} " + # -f
      	 "#{settings.makefile}" # x/makfile
    end
    return makefileCleanTask
  end


  def create_project_task(settings, deps = nil)
  	t = create_exe_task_internal(settings) if settings.type == :Executable
  	t = create_archive_task_internal(settings) if settings.type == :Library
  	
  	if (t)
	 	
	 	projDepsTask = multitask settings.name+"___PROJECTDEPS___" do |x|
	 	end
	 	
		# makefile
	    if (settings.makefile != "")
	    	projDepsTask.enhance([create_makefile_task(settings)])
	    	@makefileCleaner.enhance([create_makefile_clean_task(settings)])
	    end    	
	  	
	  	if deps
		    deps.each do |d|
		    	projDepsTask.enhance([create_project_task(d)])
		    end
		end
		
		t.enhance([projDepsTask])		    
	end
    
    return t    	
  end
  

  def create_object_file_tasks(settings)
  	objecttasks = []
  	settings.sources.each do |s|
  		objecttask = create_object_file_task(s,settings)
  		if objecttask.nil?
  			# todo: log error
			next  		
  		end
  		objecttasks << objecttask
  	end
  	objecttasks
  end

	
  def create_archive_task_internal(settings)
  	archive = settings.getArchiveName()
    register(archive)

    otasks = create_object_file_tasks(settings)
    mtask = multitask archive+"MULTI" => otasks  do |t|
    end
    res = file archive => mtask do    
      sh "#{settings.toolchainSettings[:ARCHIVER][:COMMAND]} " + # ar
      	 "#{settings.toolchainSettings[:ARCHIVER][:ARCHIVE_FLAGS]} " + # -r
      	 "#{settings.toolchainSettings[:ARCHIVER][:FLAGS]} " + # ??
      	 "#{archive} " + # debug/x.a
      	 "#{settings.sources.map{|s| settings.getObjectName(s)}.join(" ")}" # debug/src/abc.o debug/src/xy.o
    end

    return res
  end
	
	
	
  def create_exe_task_internal(settings)
    executable = settings.getExecutableName()
    register(executable)
  
    userLibs = settings.userLibs.map! {|k| "#{settings.toolchainSettings[:LINKER][:USER_LIB_FLAG]}#{k}" }.join(" ")
    libs = settings.libs.map! {|k| "#{settings.toolchainSettings[:LINKER][:LIB_FLAG]}#{k}" }.join(" ")
    libPaths = settings.libPaths.map! {|k| "#{settings.toolchainSettings[:LINKER][:LIB_PATH_FLAG]}#{k}" }.join(" ")
    libsWithPath = settings.libsWithPath.join(" ")

   	script = settings.linkerScript != "" ? "#{settings.toolchainSettings[:LINKER][:SCRIPT]} #{settings.linkerScript}" : "" # -T xy/xy.dld
  
    otasks = create_object_file_tasks(settings)
    mtask = multitask executable+"MULTI" => otasks  do |t|
    end
    res = file executable => mtask do
      sh "#{settings.toolchainSettings[:LINKER][:COMMAND]} " + # g++
      	 "#{settings.toolchainSettings[:LINKER][:MUST_FLAGS]} " + # ??
      	 "#{settings.toolchainSettings[:LINKER][:FLAGS]} " + # --all_load

      	 "#{settings.toolchainSettings[:LINKER][:EXE_FLAG]} " + # -o
      	 "#{executable} " + # debug/x.o

      	 "#{settings.sources.map{|s| settings.getObjectName(s)}.join(" ")} " + # debug/src/abc.o
      	 
      	 "#{script} " +

	   	 "#{libPaths} " +
  		
  		 # todo: wieder rein?
		 "#{settings.toolchainSettings[:LINKER][:LIB_PREFIX_FLAGS]} " + # "-Wl,--whole-archive "
      	 "#{libsWithPath} " +
      	 "#{userLibs} " +
      	 "#{libs} " +
      	 "#{settings.toolchainSettings[:LINKER][:LIB_POSTFIX_FLAGS]} " # "-Wl,--no-whole-archive "
    end

    return res
  end
	
	
  # todo: dylib als lib endung?
 

end

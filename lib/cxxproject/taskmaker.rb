require 'yaml'
require 'cxxproject/toolchain/settings'
require 'cxxproject/rake_ext'
require 'logger'
require 'benchmark'

ALL = FileList.new

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

# A class which encapsulates the generation of c/cpp artifacts like object-files, libraries and so on
# perhaps this should be reworked to toolchain with compiler, linker, ...
class Compiler
  def initialize(output_path)
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
    @output_path = output_path
    @includes = []
    CLOBBER.include(output_path)
    @defines = []
    @flags = []
    @linker_flags = []
    @benchmark = 0
  end
  def set_loglevel(level)
    @log.level = level
  end
  def set_flags(flags)
    @flags = flags
    self
  end
  def set_linker_flags(flags)
    @linker_flags = flags
    self
  end
  def set_includes(includes)
    @includes = includes
    self
  end
  def set_defines(defines)
    @defines = defines
    self
  end
  def register(name)
    CLEAN.include(name)
    ALL.include(name)
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
        "-L#{File.dirname(path)} -l#{i.name}"
      else
        "#{@output_path}/lib#{i.name}.a"
      end
    end
    return res
  end

  def include_string(d)
    includes = transitive_includes(d).uniq
    @log.debug "------------> #{includes}"
    includes.inject('') { | res, i | "#{res} -I#{i} " }
  end

  def get_flags
    @flags.map{ |f| "-#{f}"}.join(' ')
  end
  def get_linker_flags
    @linker_flags.map{ |f| "-#{f}"}.join(' ')
  end
  def get_defines
    @defines.map{ |i| "-D#{i}"}.join(' ')
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

  def create_object_file_task(lib, relative_source, base)
    defines = get_defines
    source = File.join(lib.base, relative_source)
    out = output_filename(source, :object, base)
    outputdir = File.dirname(out)
    directory outputdir
    depfile = "#{out}.dependencies"
    depfileTask = file depfile => source do
      calc_dependencies(depfile, defines, include_string(lib),source)
    end
    outfileTask = file out => depfile do |t|
      sh "g++ -c #{source} #{include_string(lib)} #{defines} #{get_flags} -o #{t.name}"
    end
    applyTask = create_apply_task(depfile,depfileTask,outfileTask)
    outfileTask.enhance([applyTask])
    depfileTask.enhance([outputdir])
    return outfileTask
  end

  def create_apply_task(depfile,depfileTask,outfileTask)
    task "#{depfile}.apply" => depfile do |task|
      deps = YAML.load_file(depfile)
      if (deps)
        outfileTask.enhance(deps)
        depfileTask.enhance(deps[1..-1])
      end
    end
  end

  def calc_dependencies(depFile, define_string, include_string, source)
    @log.info "calc_dependencies for #{depFile}"
    command = "g++ -MM #{define_string} #{include_string} #{source}"
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
  end

  def create_source_lib(lib, objects)
    fullpath = static_lib_path(lib.name)
    @log.info "create source lib:#{fullpath}"
    command = objects.prerequisites.inject("ar -r #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    @log.debug "command will be: #{command}"
    register(fullpath)
    deps = [objects].dup
    deps += lib.dependencies.map {|dep|get_path_for_lib(dep)}.flatten
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      @log.info "\nlink #{lib.name}\n"
      sh command
    end
    return res
  end

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
    lib = ALL_BUILDING_BLOCKS[d]
    if !lib
      raise "could not find library with name '#{d}'"
    end
    if (lib.instance_of?(BinaryLibrary))
      binary_lib_path(lib)
    else
      static_lib_path(lib.name)
    end
  end

  LibPrefix='-Wl,--whole-archive'
  LibPostfix='-Wl,--no-whole-archive'

  def create_exe_task(exe, objects,projects)
    exename = "#{exe.name}.exe"
    fullpath = File.join(@output_path, exename)
    command = objects.prerequisites.inject("g++ -all_load #{get_linker_flags} -o #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    dep_paths = exe.dependencies.map {|dep|get_path_for_lib(dep)}.flatten
    register(fullpath)
    deps = [objects].dup
    deps += dep_paths
    executableName = File.basename(exe.name)
    desc "link executable #{executableName}"
    task executableName.to_sym => fullpath
    res = file fullpath => deps + projects do
      command += " #{LibPrefix} " if OS.linux?
      command = transitive_libs(exe).inject(command) {|command,l|"#{command} #{l}"}
      command += " #{LibPostfix}" if OS.linux?
      sh command
    end
    create_run_task(fullpath,projects)
    return res
  end
  
  def create_run_task(p,projects)
    desc "run executable"
    task :run => projects << p do
      sh "#{p}"
    end
  end

end

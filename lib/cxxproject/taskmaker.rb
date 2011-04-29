
class TaskMaker_old

  def initialize(logger)
    @log = logger
    @flags = []
    @linker_flags = []
    @defines = []
  end

  def create_building_block_task(building_block)
    if (building_block.instance_of?(Exe)) then
      t = build_exe_task(building_block)
      # deps = building_block.dependencies
      # t.enhance(deps)
    elsif (building_block.instance_of?(SourceLibrary)) then
      t = build_source_lib_task(building_block)
      # deps = building_block.dependencies
      # t.enhance(deps)
    elsif (building_block.instance_of?(BinaryLibrary)) then
      # t = build_binary_lib_task
    # elsif (building_block.instance_of?(SingleFile)) then
    #   t = build_single_file_task
    # elsif custom_task
    #   t = build_custom_task
    else
      raise 'unknown building_block'
    end
  end

  def build_source_lib_task(building_block)
    lib = building_block.lib
    compiler = building_block.compiler
    @log.debug "building source lib"
    objects = building_block.sources.map do |s|
      create_object_file_task(building_block, s, building_block.base, building_block.outdir)
    end
    t = multitask "multitask_#{building_block}" => objects
    create_source_lib(building_block, t, building_block.outdir)
  end

  def build_exe_task(building_block)
    compiler = building_block.compiler
    objects = building_block.sources.map do |s|
      create_object_file_task(building_block, s, building_block.base, building_block.outdir)
    end
    t = multitask "multitask_#{building_block}"  => objects
    # create_exe_task(building_block, t, building_block.dependencies, building_block.outdir)
    create_exe_task(building_block, t, [], building_block.outdir)
  end

  def build_single_file_task()
  end

  def buld_custom_task()
  end

  def create_object_file_task(lib, relative_source, base, outdir)
    defines = get_defines
    source = File.join(lib.base, relative_source)
    out = output_filename(source, :object, base, outdir)
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
  LibPrefix='-Wl,--whole-archive'
  LibPostfix='-Wl,--no-whole-archive'
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

  def create_source_lib(lib, objects, outdir)
    fullpath = static_lib_path(lib.name, outdir)
    @log.info "create source lib:#{fullpath}"
    command = objects.prerequisites.inject("ar -r #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    @log.debug "command will be: #{command}"
    register(fullpath)
    deps = [objects].dup
    deps += lib.dependencies.map {|dep|get_path_for_lib(dep, outdir)}.flatten
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      @log.info "\nlink #{lib.name}\n"
      sh command
    end
    return res
  end

  def create_exe_task(exe, objects,projects, outdir)
    exename = "#{exe.name}.exe"
    fullpath = File.join(outdir, exename)
    command = objects.prerequisites.inject("g++ -all_load #{get_linker_flags} -o #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    dep_paths = exe.dependencies.map {|dep|get_path_for_lib(dep, outdir)}.flatten
    puts "dep_paths for new stuff......#{dep_paths.inspect}"
    register(fullpath)
    deps = [objects].dup
    deps += dep_paths
    puts "depfor new stuff......#{deps.inspect}"
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

  def static_lib_path(name, outdir)
    libname = "lib#{name}.a"
    fullpath = File.join(outdir, libname)
    return fullpath
  end
  def output_filename(source, type, base, outdir)
    File.join(outdir, type_to_path(type), "#{source.remove_from_start(base)}.#{type_to_ending(type)}")
  end
  def register(name)
    CLEAN.include(name)
    ALL.include(name)
  end

  def type_to_ending(type)
    case type
      when :object
        return 'o'
      else
        raise "Unknown type: #{type}"
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

  def get_path_for_lib(d, outdir)
    lib = ALL_BUILDING_BLOCKS[d]
    if !lib
      raise "could not find library with name '#{d}'"
    end
    if (lib.instance_of?(BinaryLibrary))
      binary_lib_path(lib)
    else
      static_lib_path(lib.name, outdir)
    end
  end
end


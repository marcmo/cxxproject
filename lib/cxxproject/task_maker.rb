require 'logger'
require 'benchmark'
# stores all rake tasks
ALL = FileList.new

# A class which encapsulates the generation of c/cpp artifacts like object-files, libraries and so on
class TaskMaker
  attr_reader :output_path

  # building_block_map is a mapping from unique names to building blocks
  def initialize(output_path, building_block_map, compiler_config)
    @log = Logger.new(STDOUT)
    @log.level = Logger::INFO
    @compiler = compiler_config
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

  def build_source_lib_task(lib, base)
    @log.debug "building source lib"
    objects = lib.sources.map do |s|
      create_object_file_task(lib, s, base)
    end
    t = multitask "multitask_#{lib}" => objects
    create_source_lib(lib, t)
  end

  def build_exe_task(exe, project_configs, base)
    objects = exe.sources.map do |s|
      create_object_file_task(exe, s, base)
    end
    t = multitask "multitask_#{exe}"  => objects
    create_exe_task(exe, t, project_configs)
  end

  def create_tasks_for_building_blocks(building_block, project_configs, base)
    @log.debug "convert to rake2: #{building_block}"
    if (building_block.instance_of?(SourceLibrary)) then
      build_source_lib_task(building_block, base)
    elsif (building_block.instance_of?(Exe)) then
      build_exe_task(building_block, project_configs, base)
    elsif (building_block.instance_of?(BinaryLibrary)) then
    else
      raise 'unknown building_block'
    end
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
      sh "#{@compiler[:command]} -c #{source} #{include_string(lib)} #{defines} #{get_flags} -o #{t.name}"
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
    command = "#{@compiler[:command]} -MM #{define_string} #{include_string} #{source}"
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

  LibPrefix='-Wl,--whole-archive'
  LibPostfix='-Wl,--no-whole-archive'

  def create_exe_task(exe, objects,project_configs)
    exename = "#{exe.name}.exe"
    fullpath = File.join(@output_path, exename)
    command = objects.prerequisites.inject("#{@compiler[:command]} -all_load #{get_linker_flags} -o #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    dep_paths = exe.dependencies.map {|dep|get_path_for_lib(dep)}.flatten
    register(fullpath)
    deps = [objects].dup
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

end

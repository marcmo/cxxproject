# stores all rake tasks
ALL = FileList.new

# A class which encapsulates the generation of c/cpp artifacts like object-files, libraries and so on
# perhaps this should be reworked to toolchain with compiler, linker, ...
class Compiler
  def initialize(output_path)
    @output_path = output_path
    CLOBBER.include(output_path)
  end

  def register(name)
    CLEAN.include(name)
    ALL.include(name)
  end

  def transitive_includes(lib)
    res = Dependencies.transitive_dependencies([lib.name]).map do |i|
      if (i.instance_of?(BinaryLibrary))
        i.includes
      else
        i.includes.map { |include| File.join(i.base, include) }
      end
    end
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
    includes = transitive_includes(d)
    includes.inject('') { | res, i | "#{res} -I#{i} " }
  end

  def create_object_file(lib, relative_source)
    source = File.join(lib.base, relative_source)
    out = File.join(@output_path, "#{source}.o")
    outputdir = File.dirname(out)
    directory outputdir
    register(out)
    depfile = "#{out}.dependencies"
    depfileTask = file depfile => source do
      calc_dependencies(depfile,"",include_string(lib),source)
    end
    desc "compiling #{source}"
    outfileTask = file out => depfile do |t|
      sh "g++ -c #{source} #{include_string(lib)} -o #{t.name}"
    end
    outfileTask.enhance([create_apply_task(depfile,depfileTask,outfileTask)])
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
    command = "g++ -MM #{define_string} #{include_string} #{source}"
    deps = `#{command}`
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
    command = objects.inject("ar -r #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    register(fullpath)
    deps = objects.dup
    deps += lib.dependencies.map {|dep|get_path_for_lib(dep)}.flatten
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      sh command
    end
    return res
  end

  def binary_lib_path(lib)
    lib_endings = lib.config.get_value(:lib_endings)
    if !lib_endings
      puts "no :lib_endings defined ... using default"
      lib_endings = ["a","dylib"]
    end

    lib_paths = lib.config.get_value(:lib_paths)
    if !lib_paths
      puts "no :lib_paths defined .. using default"
      lib_paths = ["/usr/local/lib","/usr/lib","/opt/local/lib"]
    end
    possibilities = lib_endings.inject([]) { |res, ending| lib_paths.inject(res) { |res, lib_path| res << File.join(lib_path, "lib#{lib.name}.#{ending}") } }
    i = possibilities.index{ |x| File.exists?(x)}
    if i
      possibilities[i]
    else
      raise "could not find libpath for #{lib} in #{lib_paths}"
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
      raise "could not find buildingblock with name '#{d}'"
    end
    if (lib.instance_of?(BinaryLibrary))
      binary_lib_path(lib)
    else
      static_lib_path(lib.name)
    end
  end

  LibPrefix='-Wl,--whole-archive'
  LibPostfix='-Wl,--no-whole-archive'

  def create_exe(exe, objects)
    exename = "#{exe.name}.exe"
    fullpath = File.join(@output_path, exename)
    command = objects.inject("g++ -all_load -o #{fullpath}") do |command, o|
      "#{command} #{o}"
    end

    dep_paths = exe.dependencies.map {|dep|get_path_for_lib(dep)}.flatten
    register(fullpath)
    deps = objects.dup
    deps += dep_paths
    desc "link exe #{exe.name}"
    res = file fullpath => deps do
      command += " #{LibPrefix} "
      command = transitive_libs(exe).inject(command) {|command,l|"#{command} #{l}"}
      command += " #{LibPostfix}"
      sh command
    end
    return res
  end

end

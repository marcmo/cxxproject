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
        path = find_lib_path(i.name)
        "-L#{path} -l#{i.name}"
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
        # p "enhancing depfileTask with #{deps}"
        depfileTask.enhance(deps[1..-1])
      end
    end
  end

  def calc_dependencies(depFile, define_string, include_string, source)
    command = "g++ -MM #{define_string} #{include_string} #{source}"
    puts command
    deps = `#{command}`
    if deps.length == 0
      raise 'cannot calc dependencies'
    end
    deps = deps.gsub(/\\\n/,'').split()[1..-1]
    p "write file #{depFile}"
    File.open(depFile, 'wb') do |f|
      f.write(deps.to_yaml)
    end
  end

  def static_lib_path(name)
    libname = "lib#{name}.a"
    fullpath = File.join(@output_path, libname)
    return fullpath
  end

  def create_source_lib(lib, objects)
    fullpath = static_lib_path(lib.name)
    command = objects.inject("ar -r #{fullpath}") do |command, o|
      "#{command} #{o}"
    end
    register(fullpath)
    deps = objects.dup
    deps += lib.dependencies.inject([]) {|acc,dep| acc += get_path_for_lib(dep)}
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      sh command
    end
    return res
  end

  def find_lib_path(d)
    libEndings = ["a","dylib"]
    paths = ["/usr/local/lib/lib","/usr/lib/lib","/opt/local/lib"]
    possibilities = libEndings.collect{|x| paths.inject([]){|acc,e| acc+["#{e}#{d}.#{x}"]}}.flatten
    i = possibilities.index{|x|File.exists?(x)}
    if i
      [possibilities[i]]
    else
      []
    end
  end

  def get_path_for_lib(d)
    lib = ALL_BUILDING_BLOCKS[d]
    if !lib
      raise "could not find buildingblock with name '#{d}'"
    end
    if (lib.instance_of?(BinaryLibrary))
      lib_path = find_lib_path(d)
      if lib_path.empty?
        raise "lib not found: #{d}"
      end
      []
    else
      [static_lib_path(lib.name)]
    end
  end

  def create_exe(exe, objects)
    exename = "#{exe.name}.exe"
    fullpath = File.join(@output_path, exename)
    command = objects.inject("g++ -all_load -o #{fullpath}") do |command, o|
      "#{command} #{o}"
    end

    dep_paths = exe.dependencies.map {|dep|get_path_for_lib(dep)}
    register(fullpath)
    deps = objects.dup
    deps += dep_paths
    desc "link exe #{exe.name}"
    res = file fullpath => deps do
      sh transitive_libs(exe).inject(command) {|command,l|"#{command} #{l}"}
    end
    return res
  end

end

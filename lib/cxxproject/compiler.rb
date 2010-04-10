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
        "-L/opt/local/lib -l#{i.name}"
      else
        "osx/lib#{i.name}.a"
      end
    end
    return res
  end

  def create_object_file(lib, relative_source)
    source = File.join(lib.base, relative_source)
    out = File.join(@output_path, "#{source}.o")
    outputdir = File.dirname(out)
    directory outputdir
    register(out)
    desc "compiling #{source}"
    res = file out => [source, outputdir] do |t|
      includes = transitive_includes(lib)
      include_string = includes.inject('') { | res, i | "#{res} -I#{i} " }
      sh "g++ -c #{source} #{include_string} -o #{t.name}"
    end
    return res
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
    deps += lib.dependencies.map {|dep|get_path_for_lib(dep)}
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      sh command
    end
    return res
  end

  def get_path_for_lib(l)
    lib = ALL_BUILDING_BLOCKS[l]
    if !lib
      raise "could not find buildingblock with name '#{l}'"
    end
    if (lib.instance_of?(BinaryLibrary))
      "/opt/local/lib/lib#{lib.name}.a"
    else
      static_lib_path(lib.name)
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

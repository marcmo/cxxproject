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
        "-L/usr/local/lib -l#{i.name}"
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
    deps += lib.dependencies.inject([]) {|acc,dep| acc += get_path_for_lib(dep)}
    desc "link lib #{lib.name}"
    res = file fullpath => deps do
      sh command
    end
    return res
  end

  def find_lib_path(d)
    libEndings = ["a","dylib"]
    paths = ["/usr/local/lib/lib","/usr/lib/lib"]
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
      # task lib_path do
      #   puts "checking if we have file #{path}"
      # end
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

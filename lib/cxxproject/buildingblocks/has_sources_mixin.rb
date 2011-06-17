require 'yaml'

module HasSources

  attr_writer :file_dependencies
  def file_dependencies
    @file_dependencies ||= []
  end

  def object_deps
    @object_deps ||= []
  end

  def sources
    @sources ||= []
  end
  def set_sources(x)
    @sources = x
    self
  end

  # used when a source file shall have different tcs than the project default
  def tcs4source(source)
    @tcs4source ||= {}

    if @tcs4source.include?(source)
      @tcs4source[source]
    else
      @tcs
    end
  end

  def set_tcs4source(x)
    @tcs4source = x
    self
  end

  def include_string(type)
    @include_string[type] ||= ""
  end

  def define_string(type)
    @define_string[type] ||= ""
  end

  def calc_compiler_strings()
    @include_string = {}
    @define_string = {}

    @incArray = []
    all_dependencies.each do |e|
      d = ALL_BUILDING_BLOCKS[e]
      next if not HasIncludes === d
      if d.includes.length == 0
        @incArray << File.relFromTo("include", d.project_dir)
      else
        d.includes.each { |k| @incArray << File.relFromTo(k, d.project_dir) }
      end
    end

    [:CPP, :C, :ASM].each do |type|
      @include_string[type] = get_include_string(@tcs, type)
      @define_string[type] = get_define_string(@tcs, type)
    end
  end

  def get_include_string(tcs, type)
    @incArray.uniq.map!{|k| "#{tcs[:COMPILER][type][:INCLUDE_PATH_FLAG]}#{k}"}.join(" ")
  end

  def get_define_string(tcs, type)
    tcs[:COMPILER][type][:DEFINES].map {|k| "#{tcs[:COMPILER][type][:DEFINE_FLAG]}#{k}"}.join(" ")
  end

  def get_object_file(source)
    parts = [complete_output_dir]

    if @output_dir_abs
      parts << 'objects'
      parts << @name
    end

    File.relFromTo(source, File.join(parts)) + ".o"
  end

  def get_dep_file(object)
    object + ".d"
  end

  def get_source_type(source)
    ex = File.extname(source)
    [:CPP, :C, :ASM].each do |t|
      return t if tcs[:COMPILER][t][:SOURCE_FILE_ENDINGS].include?(ex)
    end
    nil
  end

  def get_sources_task_name
    "Objects of #{name}"
  end

  def create_tasks_for_objects()
    object_tasks = create_object_file_tasks()
    objects_multitask = [] # needed if no sources
    if object_tasks.length > 0
      objects_multitask = multitask get_sources_task_name => object_tasks
      def objects_multitask.needed?
        return false
      end
      objects_multitask.type = Rake::Task::SOURCEMULTI
      objects_multitask.transparent_timestamp = true
    end
    [object_tasks, objects_multitask]
  end

  def parse_includes(deps)
    #deps look like test.o: test.cpp test.h -> remove .o and .cpp from list
    return deps.gsub(/\\\n/,'').split()[2..-1]
  end

  def convert_depfile(depfile)
    deps_string = read_file_or_empty_string(depfile)
    deps = parse_includes(deps_string)
    expanded_deps = deps.map do |d|
      File.expand_path(d)
    end
    od = object_deps()
    od += expanded_deps

    FileUtils.mkpath File.dirname(depfile)
    File.open(depfile, 'wb') do |f|
      f.write(expanded_deps.to_yaml)
    end
  end

  def apply_depfile(depfile,outfileTask)
    deps = nil
    begin
      deps = YAML.load_file(depfile)
      deps.each do |d|
        f = file d
        f.ignore_missing_file
        object_deps << d
      end
      outfileTask.enhance(deps)
    rescue
      # may happen if depfile was not converted the last time
      def outfileTask.needed?
        true
      end
    end
  end

  def create_object_file_tasks()
    sources.map { |source| create_object_file_task(source) }.compact
  end

  def create_object_file_task(s)
    type = get_source_type(s)
    if type.nil?
      puts "Warning: no valid source type for #{File.relFromTo(s,@project_dir)}, will be ignored!"
      return nil
    end

    source = File.relFromTo(s, @project_dir)
    object = get_object_file(s)
    the_tcs = tcs4source(s)
    depStr = type == :ASM ? "" : (the_tcs[:COMPILER][type][:DEP_FLAGS] + get_dep_file(object)) # -MMD -MF debug/src/abc.o.d

    if (@addOnlyFilesToCleanTask)
      CLEAN.include(get_dep_file(object)) if depStr != ""
      CLEAN.include(object)
    end

    build_the_task(the_tcs, object, source, depStr, type)
  end

  def build_the_task(the_tcs, object, source, depStr, type)
    compiler = the_tcs[:COMPILER][type]
    dep_file = get_dep_file(object)
    cmd = remove_empty_strings_and_join([compiler[:COMMAND], compiler[:COMPILE_FLAGS], depStr, compiler[:FLAGS], # g++ -c -depstr -g3
           get_include_string(the_tcs, type), # -I include
           get_define_string(the_tcs, type), # -DDEBUG
           compiler[:OBJECT_FILE_FLAG], object, source # -o abc.o src/abc.cpp
          ])
    res = typed_file_task Rake::Task::OBJECT, object => source do
      show_command(cmd, "Compiling #{source}")
      process_console_output(catch_output(cmd), compiler[:ERROR_PARSER])
      check_system_command(cmd)
      convert_depfile(dep_file) if depStr != ""
    end
    enhance_with_additional_files(res)
    add_output_dir_dependency(object, res, (not @addOnlyFilesToCleanTask))
    apply_depfile(dep_file, res) if depStr != ""
    res
  end

  def enhance_with_additional_files(task)
    task.enhance(@config_files)
    task.enhance(file_dependencies)
  end

  def process_console_output(console_output, ep)
    if not console_output.empty?
      highlighter = @tcs[:CONSOLE_HIGHLIGHTER]
      if (highlighter and highlighter.enabled?)
        puts highlighter.format(console_output)
      else
        puts console_output
      end

      if ep
        Rake.application.idei.set_errors(ep.scan(console_output, @project_dir))
      end
    end
  end

end

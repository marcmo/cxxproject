require 'yaml'

module HasSources

  attr_writer :file_dependencies
  def file_dependencies
    @file_dependencies ||= []
  end

  def sources
    @sources ||= []
  end
  def set_sources(x)
    @sources = x
    self
  end

  # used when a source file shall have different tcs than the project default
  def tcs4source
    @tcs4source ||= {}
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
    parts = [@complete_output_dir]
    
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
    "Sources of #{name}"
  end

  def create_tasks_for_objects()
    object_tasks = create_object_file_tasks()
    objects_multitask = []
    if object_tasks.length > 0
      objects_multitask = multitask get_sources_task_name => object_tasks
      def objects_multitask.needed?
        return false
      end
      objects_multitask.type = Rake::Task::SOURCEMULTI
      objects_multitask.transparent_timestamp = true
    end
    [object_tasks,objects_multitask]
  end

  def convert_depfile(depfile)
    deps = ""
    File.open(depfile, "r") do |infile|
      while (line = infile.gets)
        deps << line
      end
    end
    deps = deps.gsub(/\\\n/,'').split()[1..-1]
    deps.map!{|d| File.expand_path(d)}

    FileUtils.mkpath File.dirname(depfile)
    File.open(depfile, 'wb') do |f|
      f.write(deps.to_yaml)
    end
  end

  def apply_depfile(depfile,outfileTask)
    deps = nil
    begin
      deps = YAML.load_file(depfile)
      deps.each do |d|
        f = file d
        f.ignore_missing_file
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
    tasks = []

    sources.each do |s|
      type = get_source_type(s)
      if type.nil?
        puts "Warning: no valid source type for #{File.relFromTo(s,@project_dir)}, will be ignored!"
        next
      end

      source = File.relFromTo(s,@project_dir)
      object = get_object_file(s)
      depfile = get_dep_file(object)

      if tcs4source().include?s
        the_tcs = tcs4source()[s]
        iString = get_include_string(tcs, type)
        dString = get_define_string(tcs, type)
      else
        the_tcs = @tcs
        iString = include_string(type)
        dString = define_string(type)
      end

      compiler = the_tcs[:COMPILER][type]
      depStr = type == :ASM ? "" : (compiler[:DEP_FLAGS] + depfile) # -MMD -MF debug/src/abc.o.d

      cmd = [compiler[:COMMAND], # g++
        compiler[:COMPILE_FLAGS], # -c
        depStr,
        compiler[:FLAGS], # -g3
        iString, # -I include
        dString, # -DDEBUG
        compiler[:OBJECT_FILE_FLAG], # -o
        object, # debug/src/abc.o
        source # src/abc.cpp
      ].reject{|e| e == ""}.join(" ")

      if (@addOnlyFilesToCleanTask)
        CLEAN.include(depfile) if depStr != ""
        CLEAN.include(object)
      end

      outfileTask = file object => source do
        if BuildingBlock.verbose
          puts cmd
        else
          puts "Compiling #{source}" unless Rake::application.options.silent
        end

        consoleOutput = `#{cmd + " 2>&1"}`
        process_console_output(consoleOutput, compiler[:ERROR_PARSER])

        raise "System command failed: #{cmd}" if $?.to_i != 0
        convert_depfile(depfile) if depStr != ""
      end
      outfileTask.type = Rake::Task::OBJECT
      outfileTask.progress_count = 1
      outfileTask.enhance(@config_files)
      outfileTask.enhance(file_dependencies)
      add_output_dir_dependency(object, outfileTask, (not @addOnlyFilesToCleanTask))
      apply_depfile(depfile,outfileTask) if depStr != ""
      tasks << outfileTask
    end
    tasks
  end


  def process_console_output(console_output, ep)
    if not console_output.empty?
      highlighter = @tcs[:CONSOLE_HIGHLIGHTER]
      if (highlighter and highlighter.enabled?)
        puts highlighter.format(console_output)
      else
        puts console_output
      end

      if BuildingBlock.idei and ep
        BuildingBlock.idei.set_errors(ep.scan(console_output, @project_dir)) if ep
      end
    end
  end


end

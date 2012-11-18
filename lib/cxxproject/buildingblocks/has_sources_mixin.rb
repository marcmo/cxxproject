require 'yaml'
require 'cxxproject/utils/process'
require 'cxxproject/utils/utils'
require 'cxxproject/utils/printer'

module Cxxproject

  # users of this module can implement no_sources_found() to handle cases where no sources are given
  module HasSources

    attr_writer :file_dependencies
    attr_reader :incArray

    def file_dependencies
      @file_dependencies ||= []
    end

    def sources
      @sources ||= []
    end
    def set_sources(x)
      if x.class == Rake::FileList
        raise "specifying sources but FileList is empty!" if x.empty?
      end
      x.each {|f| raise "File #{f} does not exist!" unless File.exists?(f)}
      @sources = x
      self
    end

    def deps_in_depFiles
      @deps_in_depFiles ||= Set.new
    end

    def source_patterns
      @source_patterns ||= []
    end
    def set_source_patterns(x)
      @source_patterns = x
      self
    end

    def exclude_sources
      @exclude_sources ||= []
    end
    def set_exclude_sources(x)
      @exclude_sources = x
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

      @incArray = local_includes.dup
      @incArray.concat(includes)

      if Rake::application.deriveIncludes
        all_dependencies.each_with_index do |d,i|
          next if not HasIncludes === d
          next if i == 0
          if BinaryLibrary === d
            @incArray.concat(d.includes)
          else
            prefix = File.rel_from_to_project(@project_dir, d.project_dir)
            next if not prefix
            @incArray.concat(d.includes.map {|inc| File.add_prefix(prefix,inc)})
          end
        end
        @incArray.uniq!
      end

      [:CPP, :C, :ASM].each do |type|
        @include_string[type] = get_include_string(@tcs, type)
        @define_string[type] = get_define_string(@tcs, type)
      end
    end

    def get_include_string(tcs, type)
      @incArray.map {|k| "#{tcs[:COMPILER][type][:INCLUDE_PATH_FLAG]}#{k}"}
    end

    def get_define_string(tcs, type)
      if (has_tcs?)
        return tcs[:COMPILER][type][:DEFINES].map {|k| "#{tcs[:COMPILER][type][:DEFINE_FLAG]}#{k}"}
      else
        return 'only needed for spec'
      end
    end

    def get_object_file(sourceRel)
      parts = [@output_dir]
      if @output_dir_abs
        parts = [@output_dir_relPath] if @output_dir_relPath
        parts << 'objects'
        parts << @name
      end

      parts << sourceRel.chomp(File.extname(sourceRel)).gsub('..', '_')
      res = File.join(parts) + (Rake::application.preproFlags ? ".i" : ".o")
    end

    def get_dep_file(object)
      object[0..-3] + ".o.d"
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

    def parse_includes(deps)
      #deps look like "test.o: test.cpp test.h" -> remove .o and .cpp from list
      return deps.gsub(/\\\n/,'').split()[2..-1]
    end

    def convert_depfile(depfile)
      deps_string = read_file_or_empty_string(depfile)
      deps = parse_includes(deps_string)
      if deps.nil?
        return # ok, because next run the source will be recompiled due to invalid depfile
      end
      expanded_deps = deps.map do |d|
        tmp = d.gsub(/[\\]/,'/')
        deps_in_depFiles << tmp
        tmp
      end

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
          deps_in_depFiles << d
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

    def add_to_sources_to_build(sources_to_build, excluded_files, sources, alternative_toolchain=nil)
      sources.each do |f|
        next if excluded_files.include?(f)
        next if sources_to_build.has_key?(f)
        t = tcs4source(f) || alternative_toolchain
        sources_to_build[f] = t
      end
    end

    # returns a hash from all sources to the toolchain that should be used for a source
    def collect_sources_and_toolchains
      sources_to_build = {}

      exclude_files = Set.new
      exclude_sources.each do |p|
        if p.include?("..")
          Printer.printError "Error: Exclude source file pattern '#{p}' must not include '..'"
          return nil
        end

        Dir.glob(p).each {|f| exclude_files << f}
      end
      files = Set.new  # do not build the same file twice

      add_to_sources_to_build(sources_to_build, exclude_files, sources)

      source_patterns.each do |p|
        if p.include?("..")
          Printer.printError "Error: Source file pattern '#{p}' must not include '..'"
          return nil
        end

        globRes = Dir.glob(p)
        if (globRes.length == 0)
          Printer.printWarning "Warning: Source file pattern '#{p}' did not match to any file"
        end
        add_to_sources_to_build(sources_to_build, exclude_files, globRes, tcs4source(p))
      end
      return sources_to_build
    end

    # calcs a map from unique directories to array of sources within this dir
    def calc_dirs_with_files(sources)
      filemap = {}
      sources.keys.sort.reverse.each do |o|
        d = File.dirname(o)
        if filemap.include?(d)
          filemap[d] << o
        else
          filemap[d] = [o]
        end
      end
      return filemap
    end

    def create_object_file_tasks()
      sources_to_build = collect_sources_and_toolchains()
      no_sources_found() if sources_to_build.empty?

      dirs_with_files = calc_dirs_with_files(sources_to_build)

      obj_tasks = []
      dirs_with_files.each do |dir, files|
        files.reverse.each do |f|
          obj_task = create_object_file_task(f, sources_to_build[f])
          obj_tasks << obj_task unless obj_task.nil?
        end
      end
      obj_tasks
    end

    def calc_command_line_for_source(source, toolchain)
      if !File.exists?(source)
        raise "File '#{source}' not found"
      end
      if File.is_absolute?(source)
        source = File.rel_from_to_project(@project_dir, source, false)
      end

      type = get_source_type(source)
      raise "Unknown filetype for #{source}" unless type

      object = get_object_file(source)
      object_path = File.expand_path(object)
      source_path = File.expand_path(source)

      @objects << object

      depStr = ""
      dep_file = nil
      if type != :ASM
        dep_file = get_dep_file(object)
        dep_file = "\""+dep_file+"\"" if dep_file.include?(" ")
        depStr = toolchain[:COMPILER][type][:DEP_FLAGS]
      end

      compiler = toolchain[:COMPILER][type]
      i_array = toolchain == @tcs ? @include_string[type] : get_include_string(toolchain, type)
      d_array = toolchain == @tcs ? @define_string[type] : get_define_string(toolchain, type)

      cmd = [compiler[:COMMAND]]
      cmd += compiler[:COMPILE_FLAGS].split(" ")
      if dep_file
        cmd += depStr.split(" ")
        if toolchain[:COMPILER][type][:DEP_FLAGS_SPACE]
          cmd << dep_file
        else
          cmd[cmd.length-1] << dep_file
        end
      end
      cmd += compiler[:FLAGS]
      cmd += i_array
      cmd += d_array
      cmd += (compiler[:OBJECT_FILE_FLAG] + object).split(" ")
      cmd += compiler[:PREPRO_FLAGS].split(" ") if Rake::application.preproFlags
      cmd << source
      return [cmd, source_path, object_path, compiler, type]
    end

    def create_object_file_task(sourceRel, the_tcs)
      cmd, source, object, compiler, type = calc_command_line_for_source(sourceRel, the_tcs)
      depStr = ""
      dep_file = nil
      if type != :ASM
        dep_file = get_dep_file(object)
        dep_file = "\""+dep_file+"\"" if dep_file.include?(" ")
        depStr = compiler[:DEP_FLAGS]
      end
      p cmd
      res = typed_file_task Rake::Task::OBJECT, object => source do
        rd, wr = IO.pipe
        cmd << {
          :err=>wr,
          :out=>wr
        }
        sp = spawn(*cmd)
        cmd.pop
        consoleOutput = ProcessHelper.readOutput(sp, rd, wr)

        process_result(cmd, consoleOutput, compiler[:ERROR_PARSER], "Compiling #{sourceRel}")

        convert_depfile(dep_file) if dep_file

        check_config_file()
      end
      enhance_with_additional_files(res)
      add_output_dir_dependency(object, res, false)
      apply_depfile(dep_file, res) if depStr != ""
      res
    end

    def enhance_with_additional_files(task)
      task.enhance(file_dependencies)
      task.enhance(@config_files)
    end

    def process_console_output(console_output, error_parser)
      ret = false
      if not console_output.empty?
        if error_parser
          begin
            error_descs, console_output_full = error_parser.scan_lines(console_output, @project_dir)

            console_output = console_output_full if Rake::application.consoleOutput_fullnames

            ret = error_descs.any? { |e| e.severity == ErrorParser::SEVERITY_ERROR }

            console_output.gsub!(/[\r]/, "")
            highlighter = @tcs[:CONSOLE_HIGHLIGHTER]
            if (highlighter and highlighter.enabled?)
              puts highlighter.format(console_output, error_descs, error_parser)
            else
              puts console_output
            end

            Rake.application.idei.set_errors(error_descs)
          rescue Exception => e
            Printer.printWarning "Parsing output failed (maybe language not set to English?): " + e.message
            puts "Original output:"
            puts console_output
          end
        end
      end
      ret
    end

    def prepare_tasks_for_objects
      if (@output_dir_abs)
        CLEAN.include(@output_dir + "/objects/" + @name)
      end

      @objects = []
      t = multitask get_sources_task_name
      t.type = Rake::Task::SOURCEMULTI
      t.transparent_timestamp = true
      t.set_building_block(self)
      t
    end

    def no_sources_found()
      raise "No Sources found for '#{self.class} #{name}'"
    end

  end
end

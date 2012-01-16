require 'yaml'
require 'cxxproject/utils/process'
require 'cxxproject/utils/utils'
require 'cxxproject/utils/printer'

module Cxxproject
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
          prefix = File.rel_from_to_project(@project_dir,d.project_dir)
          next if not prefix
         @incArray.concat(d.includes.map {|inc| File.add_prefix(prefix,inc)})
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
      tcs[:COMPILER][type][:DEFINES].map {|k| "#{tcs[:COMPILER][type][:DEFINE_FLAG]}#{k}"}
    end

    def get_object_file(sourceRel)
      parts = [@output_dir]
      if @output_dir_abs
        parts = [@output_dir_relPath] if @output_dir_relPath
        parts << 'objects'
        parts << @name
      end

      parts << sourceRel.chomp(File.extname(sourceRel))
      File.join(parts) + ".o"
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

    def create_object_file_tasks()

      sources_to_build = {}

      exclude_files = Set.new
      exclude_sources.each do |p|
        if p.include?".."
          Printer.printError "Error: Exclude source file pattern '#{p}' must not include '..'"
          return nil
        end

        Dir.glob(p).each {|f| exclude_files << f}
      end
      files = Set.new  # do not build the same file twice

      sources.each do |f|
        if f.include?".."
          Printer.printError "Error: Source file '#{f}' must not include '..'"
          return nil
        end

        next if exclude_files.include?(f)
        next if files.include?(f)
        files << f
        sources_to_build[f] = tcs4source(f)
      end

      source_patterns.each do |p|
        if p.include?".."
          Printer.printError "Error: Source file pattern '#{p}' must not include '..'"
          return nil
        end

        globRes = Dir.glob(p)
        if (globRes.length == 0)
          Printer.printWarning "Warning: Source file pattern '#{p}' did not match to any file"
        end
        globRes.each do |f|
          next if exclude_files.include?(f)
          next if files.include?(f)
          files << f
          t = tcs4source(f)
          t = tcs4source(p) if t == nil
          sources_to_build[f] = t
        end
      end

      ordered = sources_to_build.keys.sort()
      dirs = []
      filemap = {}
      ordered.reverse.each do |o|
        d = File.dirname(o)
        if filemap.include?(d)
          filemap[d] << o
        else
          filemap[d] = [o]
	      dirs << d
        end
      end

      obj_tasks = []
      dirs.each do |d|
        filemap[d].reverse.each do |f|
          obj_task = create_object_file_task(f, sources_to_build[f])
          obj_tasks << obj_task unless obj_task.nil?
        end
      end
      obj_tasks
    end

    def create_object_file_task(sourceRel, the_tcs)
      if File.is_absolute?(sourceRel)
        sourceRel = File.rel_from_to_project(@project_dir, sourceRel, false)
      end

      type = get_source_type(sourceRel)
      return nil if type.nil?

      objectRel = get_object_file(sourceRel)
      @objects << objectRel
      object = File.expand_path(objectRel)
      source = File.expand_path(sourceRel)

      depStr = ""
      dep_file = nil
      if type != :ASM
        dep_file = get_dep_file(objectRel)
        dep_file = "\""+dep_file+"\"" if dep_file.include?" "
        depStr = the_tcs[:COMPILER][type][:DEP_FLAGS]
      end

      res = typed_file_task Rake::Task::OBJECT, object => source do
        i_array = the_tcs == @tcs ? @include_string[type] : get_include_string(the_tcs, type)
        d_array = the_tcs == @tcs ? @define_string[type] : get_define_string(the_tcs, type)

        compiler = the_tcs[:COMPILER][type]
        cmd = [compiler[:COMMAND]]
        cmd += compiler[:COMPILE_FLAGS].split(" ")
        if dep_file
          cmd += depStr.split(" ")
          if the_tcs[:COMPILER][type][:DEP_FLAGS_SPACE]
            cmd << dep_file
          else
            cmd[cmd.length-1] << dep_file
          end
        end
        cmd += compiler[:FLAGS].gsub(/\"/,"").split(" ") # double quotes within string do not work on windows...
        cmd += i_array
        cmd += d_array
        cmd += (compiler[:OBJECT_FILE_FLAG] + objectRel).split(" ")
        cmd << sourceRel

        if Cxxproject::Utils.old_ruby?
          cmd.map! {|c| ((c.include?" ") ? ("\""+c+"\"") : c )}
          cmdLine = cmd.join(" ")
          if cmdLine.length > 8000
            inputName = objectRel+".tmp"
            File.open(inputName,"wb") { |f| f.write(cmd[1..-1].join(" ")) }
            inputName = "\""+inputName+"\"" if inputName.include?" "
            consoleOutput = `#{compiler[:COMMAND] + " @" + inputName}`
          else
            consoleOutput = `#{cmd.join(" ")} 2>&1`
          end
        else
          rd, wr = IO.pipe
          cmd << {
           :err=>wr,
           :out=>wr
          }
          sp = spawn(*cmd)
          cmd.pop
          consoleOutput = ProcessHelper.readOutput(sp, rd, wr)
        end

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

  end
end

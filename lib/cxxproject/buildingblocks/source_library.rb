require 'cxxproject/buildingblocks/building_block'
require 'cxxproject/buildingblocks/has_libraries_mixin'
require 'cxxproject/buildingblocks/has_sources_mixin'

class SourceLibrary < BuildingBlock
  include HasLibraries
  include HasSources

  def initialize(name)
    super(name)
    @search_for_lib = false # false: use libs_with_path ("Eclipse mode"), true: use libs_to_search and lib_searchpaths ("Linux mode")
  end

  def complete_init()
    if @output_dir_abs
      libs_to_search << @name
      lib_searchpaths << @output_dir
    else
      libs_with_path << File.join(@output_dir,"lib#{@name}.a")
    end
  end

  def get_archive_name()
    File.relFromTo(@complete_output_dir + "/lib" + @name + ".a", @project_dir)
  end

  def get_task_name()
    get_archive_name
  end




  

  # task that will link the given object files to a static lib
  #
  def create()
  
    calc_compiler_strings()
    objects, object_multitask = create_tasks_for_objects()
  
    archive = get_archive_name()

    cmd = [@tcs[:ARCHIVER][:COMMAND], # ar
      @tcs[:ARCHIVER][:ARCHIVE_FLAGS], # -r
      @tcs[:ARCHIVER][:FLAGS], # ??
      archive, # debug/x.a
      objects.reject{|e| e == ""}.join(" ") # debug/src/abc.o debug/src/xy.o
    ].reject{|e| e == ""}.join(" ")

    res = file archive => object_multitask do
      if @@verbose
        puts cmd
      else
        puts "Creating #{archive}"
      end
      
      consoleOutput = `#{cmd + " 2>&1"}`
      process_console_output(consoleOutput)
      raise "System command failed" if $?.to_i != 0
    end
    add_file_to_clean_task(archive)
    res.enhance(@config_files)
    add_output_dir_dependency(archive, res)
    namespace 'lib' do
      desc archive
      task @name => archive
    end
    res
  end

end

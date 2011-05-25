require 'cxxproject/buildingblocks/module'
require 'cxxproject/buildingblocks/makefile'
require 'cxxproject/buildingblocks/executable'
require 'cxxproject/buildingblocks/source_library'
require 'cxxproject/buildingblocks/single_source'
require 'cxxproject/buildingblocks/binary_library'
require 'cxxproject/buildingblocks/custom_building_block'
require 'cxxproject/buildingblocks/command_line'
require 'cxxproject/extensions/rake_ext'
require 'cxxproject/extensions/file_ext'
require 'cxxproject/utils/dot/graph_writer'

require 'yaml'
require 'tmpdir'


# A class which encapsulates the generation of c/cpp artifacts like object-files, libraries and so on
class TaskMaker

  def create_tasks_for_building_block(bb)
    puts "Create tasks for #{bb.name}"
    CLOBBER.include(bb.complete_output_dir)

    bb.calc_transitive_dependencies()
    
    res = bb.create()
    
    bb.config_files.each do |cf|
      Rake.application[cf].showInGraph = GraphWriter::NO
    end
  
    # convert building block deps to rake task prerequisites (e.g. exe needs lib)  
    bb.dependencies.reverse.each do |d|
      begin
        raise "ERROR: tried to add the dependencies of \"#{d}\" to \"#{bb.name}\" but such a building block could not be found!" unless ALL_BUILDING_BLOCKS[d]
        res.prerequisites.unshift(ALL_BUILDING_BLOCKS[d].get_task_name) 
      rescue Exception => e
        puts e
        exit
      end
    end    
    
    res
  end


end

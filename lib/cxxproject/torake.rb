require 'pp'

# class which converts cxx-projects to rake-tasks
# can be used in a rakefile like:
# require 'cxxproject'
# CxxProject2Rake.new(Dir.glob('**/project.rb'), OsxCompiler.new('build'))
class CxxProject2Rake

  attr_accessor :compiler, :base

  def initialize(projects, compiler, base='./')
    @compiler = compiler
    @base = base
    projects = projects.map { |p| p.remove_from_start(base) }
    register_projects(projects)
    define_project_info_task()
    convert_to_rake()
  end

  def define_project_info_task
    desc "shows your defined projects"
    task :project_info do
      p "ProjectBase: #{@base}"
      ALL_BUILDING_BLOCKS.each_value do |bb|
        pp bb
      end
    end
  end

  def register_projects_new(project_file)
    cd(@base,:verbose => false) do |b|
      # projects.each do |project_file|
        loadContext = EvalContext.new
        cd(File.dirname(project_file),:verbose => false) do | base_dir |
          loadContext.eval_project(File.read(project_file))
          project = loadContext.myblock.call()
          project.base = File.join(@base, base_dir)
          project.to_s
        end
      # end
    end
  end
  def register_projects(projects)
    cd(@base,:verbose => false) do |b|
      projects.each do |project_file|
        loadContext = Class.new
        loadContext.module_eval(File.read(project_file))
        c = loadContext.new
        if c.respond_to?(:define_project)
          raise "no 'define_project' defined in project.rb" unless c.respond_to?(:define_project)
          cd(File.dirname(project_file),:verbose => false) do | base_dir |
            configuration = Configuration.new(File.expand_path(base_dir))
            project = c.define_project()
            project.base = File.join(@base, base_dir)
            project.to_s
          end
        else
          register_projects_new(project_file)
        end
      end
    end
  end

  def build_source_lib(lib,compiler)
    objects = lib.sources.map do |s|
      compiler.create_object_file(lib, s, @base)
    end
    compiler.create_source_lib(lib, objects)
  end

  def build_exe(exe,compiler)
    objects = exe.sources.map do |s|
      compiler.create_object_file(exe, s, @base)
    end
    compiler.create_exe(exe, objects)
  end


  def convert_to_rake
    ALL_BUILDING_BLOCKS.values.each do |building_block|
      if (building_block.instance_of?(SourceLibrary)) then
        build_source_lib(building_block,@compiler)
      elsif (building_block.instance_of?(Exe)) then
        build_exe(building_block,@compiler)
      elsif (building_block.instance_of?(BinaryLibrary)) then
      else
        raise 'unknown building_block'
      end
    end
    task :default => ALL.to_a do
    end
  end
end


class EvalContext

  attr_accessor :name, :myblock

  def cxx_configuration(name, &block)
    @myblock = block
    @name = name
  end

  def eval_project(project_text)
    instance_eval(project_text)
  end
  
  def configuration(*args, &block)
    name = args[0]
    raise "no name given" unless name.is_a?(String) && !name.strip.empty?
    instance_eval(&block)
  end

  def exe(*args)
    name = args[0]
    hash = args[1]
    exe = Exe.new(name).set_sources(hash[:sources]).set_includes(hash[:includes]).set_dependencies(hash[:dependencies])
  end
end

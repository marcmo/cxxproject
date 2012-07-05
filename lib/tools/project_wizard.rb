require 'rake'
require 'erb'
require 'rubygems'

def prepare_project(dir_name)
  begin
    require 'highline/import'
    
    say "This will create a new cxx-project config in directory: '#{dir_name}'"
    if agree("Are you sure you want to continue? [y/n] ") then
      building_block = choose_building_block
      generate_makefile = agree("Do you also whant to generate a rakefile? [y/n] ")
      
      toolchain = nil
      if generate_makefile then
        toolchain = choose_toolchain
        return unless toolchain
      end

      create_project(dir_name, building_block, toolchain, generate_makefile)
      say "Completed project-setup ;-)"
    else
      say "Stopped project-setup!"
    end
  rescue LoadError
    puts "Please run 'gem install highline'"
  end
end

def choose_building_block
  res = nil
  choose do |menu|
    say "What building-block do you want to create?"
    menu.choice(:exe) { res = "exe" }
    menu.choice(:lib) { res = "source_lib" }
    menu.prompt = "Select a building-block: "
  end
  res
end

def choose_toolchain
  res = nil
  toolchains = []
  prefix = "cxxproject_"
  toolchain_gems = Gem::Specification.find_all do |gem|
    gem.name.start_with?(prefix)
  end
  if toolchain_gems.length > 0
    choose do |menu|
      say "What toolchain do you whant to use?"
      toolchain_gems.each do |gem|
        name = gem.name[prefix.length..-1][/(.*?)toolchain/, 1] 
        menu.choice(name.to_sym) { res = name }
      end
      menu.prompt = "Select a toolchain: "
    end
  else
    say "No toolchains available!"
    candidates = `gem list --remote "cxxproject_.*toolchain"`
    say "You need to install toolchain-plugins in order to use cxxproject,- candidates are:\n#{candidates}"
  end
  res
end

def create_project(dir_name, building_block, toolchain, generate_rakefile)
  rakefile_template = IO.read(File.join(File.dirname(__FILE__),"..","tools","Rakefile.rb.template"))
  project_template = IO.read(File.join(File.dirname(__FILE__),"..","tools","project.rb.template"))
  binding = create_binding("new-item", building_block, toolchain)
  
  if !File.directory?(dir_name) then
    mkdir_p(dir_name, :verbose => false)
  end
  
  rakefile_file = "#{dir_name}/Rakefile.rb"
  if generate_rakefile && (!File.exists?(rakefile_file) || agree("Override existing '#{rakefile_file}'? [y/n] ")) then
    write_template(rakefile_file, rakefile_template, binding)
  end
  
  project_file = "#{dir_name}/project.rb"
  if !File.exists?(project_file) || agree("Override existing '#{project_file}'? [y/n] ") then
    write_template(project_file, project_template, binding)
  end
end

def create_binding(name, building_block, toolchain)
  return binding()
end

def write_template(file_name, template, binding)
  say "...write: #{file_name}"
  File.open(file_name, 'w') do |f|
    f.write ERB.new(template).result(binding)
  end
end

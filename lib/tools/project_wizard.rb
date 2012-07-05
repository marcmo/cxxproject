require 'rake'
require 'erb'
require 'rubygems'

def prepare_project(dir_name)
  begin
    require 'highline/import'
    
    say "This will create a new cxx-project in directory: '#{dir_name}'"
    if confirm("Are you sure you want to continue") then
      building_block = choose_building_block
      generate_makefile = confirm("Do you also whant to generate a rakefile", building_block.eql?("exe"))
      
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
    
  rescue Interrupt
    say "\nStopped project-setup!"
  rescue LoadError
    say "Please run 'gem install highline'"
  end
end

def choose_building_block
  res = nil
  choose do |menu|
    say "What building-block do you whant to create?"
    menu.choice(:exe) { res = "exe" }
    menu.choice(:lib) { res = "source_lib" }
    menu.prompt = "Select a building-block: "
  end
  res
end

def choose_toolchain
  res = nil
  toolchains = []
  toolchain_pattern = /cxxproject_(.*)toolchain/
  Gem::Specification.find_all do |gem|
    if gem.name =~ toolchain_pattern then
      toolchains << $1
    end
  end
  if toolchains.length > 0 then
    choose do |menu|
      say "What toolchain do you whant to use?"
      toolchains.each do |toolchain|
        menu.choice(toolchain.to_sym) { res = toolchain }
      end
      menu.prompt = "Select a toolchain: "
    end
  else
    say "No toolchains installed!"
    candidates = `gem list --remote "cxxproject_.*toolchain"`
    say "You need at least one toolchain-plugin,- candidates are:\n#{candidates}"
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
  if generate_rakefile && (!File.exists?(rakefile_file) || confirm("Override existing '#{rakefile_file}'")) then
    write_template(rakefile_file, rakefile_template, binding)
  end
  
  project_file = "#{dir_name}/project.rb"
  if !File.exists?(project_file) || confirm("Override existing '#{project_file}'") then
    write_template(project_file, project_template, binding)
  end
end

def create_binding(name, building_block, toolchain)
  return binding()
end

def write_template(file_name, template, binding)
  say "...write: '#{file_name}'"
  File.open(file_name, 'w') do |f|
    f.write ERB.new(template).result(binding)
  end
end

def confirm(question, default = true)
  res = nil
  while res == nil
    confirm = ask("#{question}? ") { |q| q.default = default ? "Y/n" : "y/N" }
    if confirm.eql?("Y/n") || confirm.downcase.eql?("yes") || confirm.downcase.eql?("y") then
      res = true
    elsif confirm.eql?("y/N") || confirm.downcase.eql?("no") || confirm.downcase.eql?("n") then
      res = false
    else
      say "Please enter \"yes\" or \"no\"."
    end
  end
  return res
end

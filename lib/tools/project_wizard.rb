require 'rake'
require 'erb'
require 'rubygems'

def choose_toolchain
  res = nil
  toolchains = []
  prefix = "cxxproject_"
  toolchain_gems = Gem::Specification.find_all do |gem|
    gem.name.start_with?(prefix)
  end
  if toolchain_gems.length > 0
    choose do |menu|
      menu.prompt = "choose a toolchain:"
      toolchain_gems.each do |gem|
        name = gem.name[prefix.length..-1]
        menu.choice(name.to_sym) { res = name }
      end
    end
  else
    say "no toolchains found...you need to install toolchain-gems in order to use cxxproject"
  end
  res
end

def choose_building_block
  res = nil
  choose do |menu|
    menu.prompt = "what building block do you want to start with?"

    menu.choice(:exe) { res = "exe" }
    menu.choice(:lib) { res = "source_lib" }
  end
  res
end

def choose_generate_makefile
  res = true
  choose do |menu|
    menu.prompt = 'generate rakefile?'
    menu.choice(:yes) { res = true }
    menu.choice(:no) { res = false }
  end
  res
end

def prepare_project(d)
  begin
    require 'highline/import'

    if agree("This will create a new cxx-project config in dir \"#{d}\" \nAre you sure you want to continue? [yn] ")
      tc = choose_toolchain
      return unless tc
      bb = choose_building_block
      generate_makefile = choose_generate_makefile

      create_project(d, bb, tc, generate_makefile)
    else
      say "stopped project creation"
    end
  rescue LoadError
    puts "Please 'gem install highline'"
  end
end


def create_project(d, bb, tc, generate_rakefile)
  rakefile_template = File.join(File.dirname(__FILE__),"..","tools","Rakefile.rb.template")
  projectrb_template = File.join(File.dirname(__FILE__),"..","tools","project.rb.template")
  s1 = IO.read(rakefile_template)
  s2 = IO.read(projectrb_template)
  name = "testme"
  building_block = bb
  toolchain_name = tc[/(.*?)toolchain/,1] 
  mkdir_p(d, :verbose => false)
  cd(d,:verbose => false) do
    if ((File.exists? "Rakefile.rb") || (File.exists? "project.rb"))
      abort "cannot create project in this directory, existing files would be overwritten!"
    end
    if generate_rakefile
      write_template('Rakefile.rb', s1, binding)
    end
    write_template('project.rb', s2, binding)
  end
end

def write_template(name, template_string, b)
  File.open(name, 'w') do |f|
    f.write ERB.new(template_string).result(b)
  end
end

require 'rake'
require 'erb'

def prepare_project(d)
  require 'highline/import'
  if agree("This will create a new cxx-project config in dir \"#{d}\" \nAre you sure you want to continue? [yn] ")
    bb = nil
    choose do |menu|
      menu.prompt = "what building block do you want to start with?"

      menu.choice(:exe) { bb = "exe" }
      menu.choices(:lib) { bb = "source_lib" }
    end

    create_project(d, bb)
  else
    say "stopped project creation"
  end
end

def create_project(d, bb)
  rakefile_template = File.join(File.dirname(__FILE__),"..","tools","Rakefile.rb.template")
  projectrb_template = File.join(File.dirname(__FILE__),"..","tools","project.rb.template")
  s1 = IO.read(rakefile_template)
  s2 = IO.read(projectrb_template)
  name = "testme"
  building_block = bb
  template1 = ERB.new s1
  template2 = ERB.new s2
  mkdir_p(d, :verbose => false)
  cd(d,:verbose => false) do
    if ((File.exists? "Rakefile.rb") || (File.exists? "project.rb"))
      abort "cannot create project in this directory, existing files would be overwritten!"
    end
    File.open("Rakefile.rb", 'w') do |f|
      f.write template1.result(binding)
    end
    File.open("project.rb", 'w') do |f|
      f.write template2.result(binding)
    end
  end
end



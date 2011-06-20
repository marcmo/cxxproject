require 'fileutils'
require 'rake/clean'

NR_OF_PROJECTS = 100
PROJECTS = {}
MAX_SOURCES = 20
MAX_FIB = 12

directory 'gen'

def create_project(name)
  base = File.join('gen', "project_#{name}")
  FileUtils.mkdir_p(base)
  sources = rand(MAX_SOURCES)
  PROJECTS[name] = sources
  sources.times do |i|
    File.open(File.join(base, "#{name}_file_#{i}.cxx"), 'w') do |io|
      io.puts("#include <stdio.h>\n#include \"../../fak.h\"\nvoid print_#{name}_#{i}() {printf(\"%ld\\n\", fib<#{rand(MAX_FIB)+1}>::value);}")
    end
  end
  File.open(File.join(base, "lib_#{name}.h"), 'w') do |io|
    sources.times do |i|
      io.puts("void print_#{name}_#{i}();")
    end
  end

  File.open(File.join(base, 'project.rb'), 'w') do |io|
    io.puts('cxx_configuration do')
    io.puts("  source_lib '#{name}', :sources => Dir.glob('*.cxx'), :includes => '.'")
    io.puts('end')
  end
end

desc "Creating #{PROJECTS} projects"
task :create_projects => [:gen] do
  NR_OF_PROJECTS.times do |i|
    create_project(i)
  end
end

desc 'creating rakefile'
task 'Rakefile.rb' => [:gen] do
  File.open(File.join('gen', 'Rakefile.rb'), 'w') do |io|
    io.puts("$:.unshift File.join(File.dirname(__FILE__),'..','..','..','lib')")
    io.puts("require 'cxxproject'")
    io.puts("CxxProject2Rake.new(Dir.glob('**/*project.rb'), 'build', GCCChain, '.')")
  end
end

desc 'create a main project'
task :create_main => [:create_projects, :gen] do
  base = File.join('gen', 'main')
  FileUtils.mkdir_p(base)
  File.open(File.join(base, 'main.cxx'), 'w') do |io|
    NR_OF_PROJECTS.times do |i|
      io.puts("#include \"lib_#{i}.h\"")
    end
    io.puts('#include <stdio.h>')
    io.puts('int main(int argc, char** args) {')
    NR_OF_PROJECTS.times do |name|
      PROJECTS[name].times do |i|
        io.puts("  print_#{name}_#{i}();")
      end
    end
    io.puts('  printf("\\n");')
    io.puts('}')
  end
  deps = []
  NR_OF_PROJECTS.times do |i|
    deps << "'#{i}'"
  end
  File.open(File.join(base, 'project.rb'), 'w') do |io|
    io.puts('cxx_configuration do')
    io.puts("  exe 'main', :sources => ['main.cxx'], :dependencies => [#{deps.join(', ')}]")
    io.puts('end')
  end
end

task :default => [:create_main, 'Rakefile.rb']
CLEAN.include('gen')

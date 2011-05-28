
## Setup Tool

Cxxproject comes with a little helper command-line tool that helps with
- creating a basic building-block description (project.rb)
- creating a rudimentary rakefile that instantiates the project

    cxx tmp

start the setuptool using for a project in the tmp directory

    This will create a new cxx-project config in dir "tmp" 
    Are you sure you want to continue? [yn] 

You can of course also use an existing directory. If the directory doesn't exist, it will be created.

    1. exe
    2. lib
    what building block do you want to start with?

So now you have the option to create a building block for either an executable or source-library.
Let's say we select the exe option, now we get 2 files:

### project.rb (describes the executable building block)

    cxx_configuration do
      exe "testme",
        :sources => FileList['**/*.cpp'],
        :includes => ['include'],
        :dependencies => []
    end

### Rakefile.rb (entry point and instantiation of the build environment)

    require 'cxxproject'
    BuildDir = "BuildDir"

    unittest_flags = {
      :DEFINES => ['UNIT_TEST','CPPUNIT_MAIN=main'],
      :FLAGS => "-O0 -g3 -Wall"
    }
    toolchain = Provider.modify_cpp_compiler("GCC", unittest_flags)
    dependent_projects =  ['./project.rb']
    CxxProject2Rake.new(dependent_projects, BuildDir, toolchain, './')

  

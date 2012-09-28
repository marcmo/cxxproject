
## Setup Tool

Cxxproject comes with a little helper command-line tool that helps with
- creating a basic building-block description (project.rb)
- creating a rudimentary rakefile that instantiates the project

<pre class="terminal">
  $ cxx tmp
</pre>

start the setuptool using for a project in the tmp directory

<pre class="terminal">
  This will create a new cxx-project config in dir "tmp" 
  Are you sure you want to continue? [yn] 
</pre>

You can of course also use an existing directory. If the directory doesn't exist, it will be created.

<pre class="terminal">
  1. exe
  2. lib
  what building block do you want to start with?
</pre>

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
      :FLAGS => ["-O0","-g3","-Wall"]
    }
    TC = "gcc"
    cxx(FileList['./project.rb'], BuildDir, TC, './') do
      Provider.modify_cpp_compiler(TC, unittest_flags)
    end

  

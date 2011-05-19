# cxxproject

Building c/c++ projects is often done with make or an ide backed system a la visual studio/eclipse etc.
Makefiles are the most flexible solution, IDEs offer some comfort but configurations are often not very accessible.

cxxproject is a utility library that aims for a simple but still powerful make-alternative for c++ projects.
It is heavily based on [rake](http://rake.rubyforge.org) and project configurations are formulated as Ruby EDSL, e.g.:

    cxx_configuration do
      exe "basic",
        :sources => FileList['**/*.cpp'],
        :dependencies => ['2']
      exe "debug",
        :sources => FileList['**/*.cpp'],
        :dependencies => ['2_debug']
    end

The base of each cxxproject are a set of building-blocks.
One ore more building-blocks are described by a small project.rb file which specifies which

  * sources are to compile
  * includes to add
  * defines to use
  * ...

A typically rakefile that uses this system simply collects all project.rb files and feeds them into the CxxProject2Rake-helper.

    require 'cxxproject'

    BuildDir="build"
    CxxProject2Rake.new(['basic/project.rb','lib1/project.rb'], BuildDir, GCCChain)

### Why Ruby?

Ruby makes for a nice syntax of the project configurations and gives you the power of a first-class scripting language for any additional things you want to achieve using cxxproject.
Of course, EDSLs suffer the drawback that they can be a little awkward to use for non-programmers... but since cxxproject is aimed at programmers that is not an issue for us :)
and...not to forget: rake makes a simple but very powerful basis.

### Examples

see [examples directory](https://github.com/marcmo/cxxproject/tree/master/example) for some examples of the cxxproject.

* basic - shows you the basic usage of sourcelibraries, executables and dependencies
* three_tests - shows you an "real life" example of two test-suites that are linked together to three executable (suite1-exe, suite2-exe and suite1+suite2-exe)

### Tests

There are three kinds of tests:

* [spec files](https://github.com/marcmo/cxxproject/tree/master/spec)
* roodi
* the [examples](https://github.com/marcmo/cxxproject/tree/master/example): use rake -T to find out about the ways to use

### Prerequisites

gems: [rspec](http://rspec.info/), [roodi](http://roodi.rubyforge.org) (optional)
libs: cppunit (only required for some examples)

### Installation

    rake install

should install the freshly built gem (if you need sudo, please install the package by hand via rake package; sudo gem install pkg/...)

    cd examples; rake 

should compile all examples and let the executables run



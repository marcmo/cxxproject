
## Basic Usage

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

A typically rakefile that uses this system simply collects all project.rb files and feeds them into the cxx-helper.

    require 'cxxproject'

    BuildDir="build"
    cxx(
      FileList['**/project.rb'], BuildDir, "clang")


### Examples

see [examples directory](https://github.com/marcmo/cxxproject/tree/master/example) for some examples of the cxxproject.

* basic - shows you the basic usage of sourcelibraries, executables and dependencies
* three_tests - shows you an "real life" example of two test-suites that are linked together to three executable (suite1-exe, suite2-exe and suite1+suite2-exe)

### Tests

There are three kinds of tests:

* [spec files](https://github.com/marcmo/cxxproject/tree/master/spec)
* roodi
* the [examples](https://github.com/marcmo/cxxproject/tree/master/example): use rake -T to find out about the ways to use


# cxxproject

cxxproject is a utility library that enables to specify c++ projects easily.

the base of each cxxproject are a set of projects (each project is described by a small project.rb file which specifies which sources are to compile, which includes to add, which defines to use, ...)

a typically rakefile that uses this system simply collects all project.rb
files and feeds them into the CxxProject2Rake-helper.

## examples

see the examples directory for some examples of the cxxproject.

* basic - shows you the basic usage of sourcelibraries, executables and dependencies
* three_tests - shows you an "real life" example of two test-suites that are linked together to three executable (suite1-exe, suite2-exe and suite1+suite2-exe)

## hacking

there are three kinds of tests:

* spec files
* roodi
* the examples: use rake -T to find out about the ways to use

## prerequisites

gems: rspec, roodi (optional)
libs: cppunit (only required for some examples)

## installation

* rake install should install the freshly built gem (if you need sudo, please install the package by hand via rake package; sudo gem install pkg/...)
* cd examples; rake (should compile all examples and let the executables run)


# cxxproject


see documentation page: [cxxproject](http://marcmo.github.com/cxxproject)

## Change History:

v_0.5.56 => v_0.5.58

    * GCC3 include not found error now recognized correctly
    * Preprocessor option added

v_0.5.55 => v_0.5.56

    * bugfix: diab error parser regex

v_0.5.54 => v_0.5.55

    * Accidentially suppressed compiler output in last version

v_0.5.53 => v_0.5.54

    * Show linking message during linking

v_0.5.52 => v_0.5.53

    * Abort build if circular deps are detected

v_0.5.51 => v_0.5.52

    * updated to ruby 1.9.3
    * includes in cxx-dsl also works with one string, some whitespace cleanup
    * prepared for next version
    * More intelligent gcc linker error parser
    * Fixed possible hang on Linux when sockets are used
    * Fixed possible hang on Linux when sockets are used, second try
    * Possibility to add empty lines for toolchain commands

v_0.5.50 => v_0.5.51

    * Improved Diab compiler error parser (not all error messages have etoa:<num> included)
    * Removed warning for ruby 1.8.6
    * Giving access to prereqs of a task
    * Fixed TI linker error parser
    * Treat step as error if parser finds an error even if step has return with 0
    * 0.5.51

v_0.5.49 => v_0.5.50

    * Fixed valgrind require/stderr bugs

v_0.5.47 => v_0.5.49

    * fixes #96: add support for valgrind
    * moved valgrind support from ext to utils, because its not a monkey patch
    * Improved diab linker error parser
    * 0.5.49

v_0.5.46 => v_0.5.47

    * more examples for usage of custom blocks
      
      bumped version
      updated README

v_0.5.45 => v_0.5.46

    * fixed linux socket problem, fixed encoding of ide messages
    * version 0.5.46
    * corrected load error in rakefile
    * better comments

v_0.5.44 => v_0.5.45

    * better error message in case of syntax errors in project.rb files
    * extended support for custom building block: can now have dependencies
      
      also included some example usage
    * better error messages for users when we have a syntax error in project.rb files
    * include output directory for CLOBBER task
    * more robust rakefile in case not all required gems are installed
      
      version bump
    * version bump

v_0.5.43 => v_0.5.44

    * Added possibility to kill CommandLine and Makefile
    * 0.5.44

v_0.5.42 => v_0.5.43

    * changed gemset version for rvm
    * don't use --whole-archive option on mac os'
      updated the change history

v_0.5.41 => v_0.5.42

    * error incompatible to ruby 1.8.6

v_0.5.40 => v_0.5.41

    * Added workaround for deadlock bug in ruby 1.8.7p352. Improved TI error parser

v_0.5.39 => v_0.5.40


v_0.5.38 => v_0.5.39

    * Fixed cleanup method for specs
    * Added option to show full filename output for compiler

v_0.5.37 => v_0.5.38

    * added ti compiler toolchain
    * Fixed -o compiler flag handling

v_0.5.36 => v_0.5.37

    * Bugfix: build always bailed out on error. Changed: dependency added to multitask intead of lib/exe if specified

v_0.5.34 => v_0.5.36

    * Cosmetic: removed unused method
    * Disallow sources with '..' . If prereq failed, files shall not be compiled. Nicer handling of unknown severity, e.g. when compiler has language different to English
    * Order of libs, userlibs, searchpath was not correct. Removed linker suppression for executables

v_0.5.33 => v_0.5.34

    * Fixed warning for regex in ruby 1.8.6
    * Refactored error output: colorizing simplified (ONE color for each severity), error msg if return value of command not 0 and error parser has nothing found, unnecessary command failed message removed in cases where error message are already printed.
    * Files with errors are shown at the end if bail_on_first_error (most part of this change was done in the last commit)
    * Added explanation for bad filedescriptor problem
    * Removed attribute helper spec - this feature is not part of cxxproject anymore
    * Removed linkinfo and versiongenerator. Touch config file if changed during build.

v_0.5.32 => v_0.5.33

    * output of objects without org file ext. some minor cleanup

v_0.5.31 => v_0.5.32

    * 0.5.31
    * updated README
    * Makefile and CommandLine output immediately visible instead of waiting until the step has been completed. Bugfix: attribute pathTo of Makefile did not work for Build This Project Only

v_0.5.30 => v_0.5.31

    * Bugfix: GCC error parser broken if column is included. Bugfix: If line has no error and colorizer is on, the newline was dismissed.
    * GCC can have fatal errors, fixed error parser
    * Merged and improved ide messages about building projects

v_0.5.28 => v_0.5.30

    * Unnecessary include check was broken
    * config file check now AFTER executing task to avoid inconsistencies due to intermediate-changes of config files
    * Colorizing not compatible with ruby 1.8.6

v_0.5.27 => v_0.5.28

    * Minor fix for lib search path on Windows
    * backticks on windows do not work with slashes

v_0.5.26 => v_0.5.27

    * config file in torake now absolute
    * 0.5.27

v_0.5.25 => v_0.5.26

    * Config files are checked right before building, which minimizes the chance for inconsistent dependency graphs when changing config files during build

v_0.5.24 => v_0.5.25

    * Bugfix: removed old and therefore invalid require
    * Some error parser fixes
    * Bugfix: libs were not checked correctly in 'in build this project only'
    * Warning if source pattern does not match to any file
    * Ignore bad filedescriptor for output

v_0.5.23 => v_0.5.24

    * ide interface was not compatible to ruby 1.8.x when reading non-blocking from socket

v_0.5.22 => v_0.5.23

    * Removed require to deleted file

v_0.5.21 => v_0.5.22

    * marshall string for lake cache is shorter now
    * Added info output about possible unnecessary includes
    * build_linkinfo was not set correctly, added getter methods for build_linkinfo and build_version_file
    * check unnecessary includes now off per default, can be switched on
    * Reintroduced helper deps
    * missing makefile path is an error, not a warning
    * Adjusted module building block for lake
    * Added possibility to suppress the linking
    * Cosmetic: string compare in test failed after changing string in lib
    * cosmetic, error msg was not printed out correctly
    * bugfix: building only exe did not check libs
    * added a second color scheme for light (e.g. white) backgrounds
    * 0.5.22

v_0.5.20 => v_0.5.21

    * fixed uncolored output on linux
    * Removed transitive_config stuff. moved attribute helper stuff into spec and commented out, because it's not used anymore
    * typo in warning message of makefile buildingblock
    * removed tests for transitive_configs
    * transitive includes is off per default -> for cxx it is switched on
    * Removed helper dependencies, which are not needed anymore by lake. added test-warnings for bad filedescritor bug, which still occurs on windows - will be removed after fixing
    * 0.5.21

v_0.5.19 => v_0.5.20

    * cosmetic: removed unused method
    * Fixed bad filedescriptor bug - sometimes a pipe was not working properly after read_nonblock
    * added error if symlink has other parent dir than target
    * added/changed LinkInfo/VersionGenerator feature, artifact name is configurable

v_0.5.18 => v_0.5.19

    * bugfix: errors in diab can be fatal too
    * flags for make are set individually
    * minor cleanup

v_0.5.17 => v_0.5.18

    * interface spec is running again
    * libs without objects working again
    * 0.5.18
    * backtrace for finding bad filedescriptor bug, which occurs very rarely

v_0.5.16 => v_0.5.17

    * Same object order as in Eclipse. Archives are built from objects dir to shorten the cmd length
    * Cosmetic: removed useless line
    * 0.5.17

v_0.5.15 => v_0.5.16

    * windows probs with double quotes, tcs for single file not applied correctly
    * 0.5.16

v_0.5.14 => v_0.5.15

    * error parser fixed for makefiles, commandlines. fixed windows path problems, sources always build in alphabetical order
    * version 0.5.15

v_0.5.13 => v_0.5.14

    * updated release history
    * fixes #84: stdout will now be on stdout again
    * improvements for referencing output dir
    * version update

v_0.5.12 => v_0.5.13

    * version available in code
    * stderr and stdout were mixed up
    * added double ticks if lib pathes have spaces
    * fixed cleaning and some other minor stuff
    * 0.5.13

v_0.5.11 => v_0.5.12

    * minor code cleanup
    * fixed linker lib string, some stuff may have been missed
    * 0.5.12

v_0.5.10 => v_0.5.11

    * Fixed gemspec, should be compatible to more rubygems versions
    * yaml required before loading gemspec
    * Removed default flags from toolchains
    * 0.5.11

v_0.5.8 => v_0.5.10

    * Fixed some bugs like handling of 0, specs are running again
    * fixed clang compiler formatter (runtime error because formatter api changed)
    * console output was not captured correctly for old ruby versions
      
      happened for ruby versions < 1.9.2...fixed with this commit
    * fixed namespace error for Printer
    * 0.5.10

v_0.5.7 => v_0.5.8

    * better matches for gcc warnings/error parser
    * some formatter tweaking...
      
      added rake task to automatically generate and update release history

v_0.5.6 => v_0.5.7

    * possibility to add path vars for makefile
    * version 0.5.7

v_0.5.5 => v_0.5.6

    * added version history
    * error parsing for diab, nicer output, error parser for linker
    * compile linkinfo only if necessary
    * bugfix: error if linkinfo not set
    * improved color and output

v_0.5.4 => v_0.5.5

    * startet to add new errorparser (#82)
    * command line colorization and ide interface use same formatter now
      
      closes #82, #83
      regex for parsing the error string is now part of the toolchain,
      colorizing_formatter now uses errorparser to parse command line output
      version bump

v_0.5.3 => v_0.5.4

    * Removed dot graph stuff
    * fixed non-ascii char console prob in windows
    * polish
    * corrected console highlighting (closes #81)
    * version bump to 0.5.4
      
      install dependent gems per default,
      enable "on" as keyword for toggling the colorized output

v_0.5.3.32 => v_0.5.3


v_0.5.2 => v_0.5.3.32

    * exit helper for unit tests
    * 0.5.3
    * Removed dot graph stuff
    * fixed non-ascii char console prob in windows
    * polish
    * corrected console highlighting (closes #81)
    * version bump to 0.5.4
      
      install dependent gems per default,
      enable "on" as keyword for toggling the colorized output
    * startet to add new errorparser (#82)
    * command line colorization and ide interface use same formatter now
      
      closes #82, #83
      regex for parsing the error string is now part of the toolchain,
      colorizing_formatter now uses errorparser to parse command line output
      version bump
    * added version history
    * error parsing for diab, nicer output, error parser for linker
    * compile linkinfo only if necessary
    * bugfix: error if linkinfo not set
    * improved color and output
    * possibility to add path vars for makefile
    * version 0.5.7
    * better matches for gcc warnings/error parser
    * some formatter tweaking...
      
      added rake task to automatically generate and update release history
    * Fixed some bugs like handling of 0, specs are running again
    * fixed clang compiler formatter (runtime error because formatter api changed)
    * console output was not captured correctly for old ruby versions
      
      happened for ruby versions < 1.9.2...fixed with this commit
    * fixed namespace error for Printer
    * 0.5.10
    * Fixed gemspec, should be compatible to more rubygems versions
    * yaml required before loading gemspec
    * Removed default flags from toolchains
    * 0.5.11
    * minor code cleanup
    * fixed linker lib string, some stuff may have been missed
    * 0.5.12
    * version available in code
    * stderr and stdout were mixed up
    * added double ticks if lib pathes have spaces
    * fixed cleaning and some other minor stuff
    * 0.5.13
    * updated release history
    * fixes #84: stdout will now be on stdout again
    * improvements for referencing output dir
    * version update
    * error parser fixed for makefiles, commandlines. fixed windows path problems, sources always build in alphabetical order
    * version 0.5.15
    * windows probs with double quotes, tcs for single file not applied correctly
    * 0.5.16
    * Same object order as in Eclipse. Archives are built from objects dir to shorten the cmd length
    * Cosmetic: removed useless line
    * 0.5.17
    * interface spec is running again
    * libs without objects working again
    * 0.5.18
    * backtrace for finding bad filedescriptor bug, which occurs very rarely
    * bugfix: errors in diab can be fatal too
    * flags for make are set individually
    * minor cleanup
    * cosmetic: removed unused method
    * Fixed bad filedescriptor bug - sometimes a pipe was not working properly after read_nonblock
    * added error if symlink has other parent dir than target
    * added/changed LinkInfo/VersionGenerator feature, artifact name is configurable
    * fixed uncolored output on linux
    * Removed transitive_config stuff. moved attribute helper stuff into spec and commented out, because it's not used anymore
    * typo in warning message of makefile buildingblock
    * removed tests for transitive_configs
    * transitive includes is off per default -> for cxx it is switched on
    * Removed helper dependencies, which are not needed anymore by lake. added test-warnings for bad filedescritor bug, which still occurs on windows - will be removed after fixing
    * 0.5.21
    * marshall string for lake cache is shorter now
    * Added info output about possible unnecessary includes
    * build_linkinfo was not set correctly, added getter methods for build_linkinfo and build_version_file
    * check unnecessary includes now off per default, can be switched on
    * Reintroduced helper deps
    * missing makefile path is an error, not a warning
    * Adjusted module building block for lake
    * Added possibility to suppress the linking
    * Cosmetic: string compare in test failed after changing string in lib
    * cosmetic, error msg was not printed out correctly
    * bugfix: building only exe did not check libs
    * added a second color scheme for light (e.g. white) backgrounds
    * 0.5.22
    * Removed require to deleted file
    * ide interface was not compatible to ruby 1.8.x when reading non-blocking from socket
    * Bugfix: removed old and therefore invalid require
    * Some error parser fixes
    * Bugfix: libs were not checked correctly in 'in build this project only'
    * Warning if source pattern does not match to any file
    * Ignore bad filedescriptor for output
    * Config files are checked right before building, which minimizes the chance for inconsistent dependency graphs when changing config files during build
    * config file in torake now absolute
    * 0.5.27
    * Minor fix for lib search path on Windows
    * backticks on windows do not work with slashes
    * Unnecessary include check was broken
    * config file check now AFTER executing task to avoid inconsistencies due to intermediate-changes of config files
    * Colorizing not compatible with ruby 1.8.6
    * Bugfix: GCC error parser broken if column is included. Bugfix: If line has no error and colorizer is on, the newline was dismissed.
    * GCC can have fatal errors, fixed error parser
    * Merged and improved ide messages about building projects
    * 0.5.31
    * Makefile and CommandLine output immediately visible instead of waiting until the step has been completed. Bugfix: attribute pathTo of Makefile did not work for Build This Project Only

v_0.5.1 => v_0.5.2

    * Fixed 1.8.6 compatibility, removed transitive_config_deps
    * again, the 8192 lines problem and 1.8.6 compatibility
    * deleted some files which were added accidentially
    * fixed bug with makefile building block generation
    * fixed task name probs for command line and makefile
    * removed dependencies because they should be optional

v_0.5.0 => v_0.5.1

    * fix for spawn, only transitive_config_files in prereqs - #68, #75
    * removed debug output - #68
    * added better errormessage when there is a problem with a project.rb file
      
      include directory from which the failed command was executed
    * fixed error in gemspec
    * fixed transitive config spec and ruby 1.8.7 compatibility #80

v_0.4.10 => v_0.5.0

    * autorefresh after run task - Fixes #58
    * renamed variable - #56
    * added dialog to enter filter (defaults to .*) - Fixes #59
      
      update of details after invoke
    * better open editor - Fixes #60
    * refactoring of last commits - #24
    * Bugfix for /0 - Fixes #61
    * optional task in rakefile for rdoc - #62
    * use no local variable but simple join - #56
    * bugifx: error msg were not sent correctly
    * bugfix: no sources in lib not handled correctly
    * bugfix: missing parameters, re-cleaned up compiler args
    * refactoring and test for error-packets in ide_interface
    * nr of sourcefiles per executable - #63
    * added rcov flags to rakefile and fixed ThreadOut accordingly - Fixes #64
      
      coverage is generated into coverage/
    * Speeded up creating rake tasks
    * bugfix for speed improvements
    * monkey patched Task::enhance - #68
    * Bugfix: clean task is created before monkey patching Rake::Task
    * ok ... new philosophy ... everything should be as optional as possible - #66
      
      lets see how much rdoc, rake, ... is delivered with 1.8.7 and 1.9.2 (our two supported ruby-interpreters)
    * better warning when a building block is malformed
    * closes #70 - gcov in not needed to execute specs
      
      there was a load error when gcov gem was not installed
    * rename of extensions (closes #71)
      
      now all extensions reside in ext folder and are not called *_ext.rb anymore
    * introduced modules for all files
    * added coverage tool for 1.9
      
      used simplecov (optional package)
    * added google-perftools support - #68
    * some more tests for relFromTo - #65
    * added lazy_attribute_with_default - #67
      
      added rake_helper/perftools.rb
    * bugfix for osx - a33eeaf254ef8abaeae0
    * preparation of caching. glob on-the-fly. bugfix all_deps.
    * re-fixed indention
    * removed complete_init2, specs are running again
    * Enhance multitask 'directly'
    * refactored: execution of building blocks in project dir - fixes some minor bugs, little speed up
    * cosmetic: indention
    * cosmetic: underscore instead of camelcase for methods
    * fixed prereq working dir of multi tasks
    * fixed prereq working dir of multi tasks
    * added console task to torake - Fixes #72
    * more tests for attribute helper - #67
    * path names are relative again
    * fixed some relative pathes errors
    * some docu - #2
    * bin_libs(name1, name2, name3) added - #74
    * added support for symbols - Fixes #74
    * added attribute_helper lazy init from calculation - #67
    * started to add new toochain #23
    * added easier API for defining multiple BinaryLibrary building blocks,
      closes #74
    * fixed tests for #23
    * local includes, archives with cmd length > 8192
    * enhanced test - #67
    * removed debug output - #23
    * defined spectask - #Fixes #77
      
      added spectask to point to spec:spec and spec:coverage which should be used instead
    * made highline optional - Fixes #78
    * using spawn instad of backtricks prevents 8192 max char problem
    * more flexible BinaryLib (now compatible to Lake)
    * made some required gems optional

v_0.4.9 => v_0.4.10

    * optional rbcurses ui - #46

v_0.4.8 => v_0.4.9

    * link documentation from readme
    * moved svg to ghpages
    * added formatter to gcc toolchain
    * output is controlled by rake flags
      
      corrected all examples,
      rake -v -> logger->info & BuildingBlock.verbose, rake -t -> logger->debug
    * mini readme for grapgstream server
    * #17 - run:all\[filter\]
    * removed dummy task
    * #17 - added more generic tasks
      
      filter[], lib:filter[], exe:filter[], run:filter[]
    * #13, #15 - llvm clang support
      
      you have to download and install clang binaries as well as llvm-gcc front end binaries and set the path to the bin folders
    * polish
    * Fixes #16 - adapted colors to look correct
    * Fixes #18
    * fixing color and toolchain (did not run anymore), graph writer now more configurable (type instead of YES and NO), minor improvements
    * removing only the root-outputdir, not all subdirs
    * specs are running again
    * #27 - apply will be executed immediately
    * Fixes #28
      
      enabled is now a static variable of ColorizingFormatter. The instances simply forward to that static field. By default it is false, so no colorization takes place. torake sets it to true be default, but you also have an additional task to enable/disable it again (toggle_colorization)
    * emit compiler command when we have a compiler error
    * Bugfix of >Fixes #28<: did not run without rainbow
    * Fixes #25
      
      protobuf addressbook_(read|write).exe including:
      protobuf download
      protobuf configure
      protobuf make to get protoc
      call to protoc to generate sources
    * Fixes #29
      
      added question for generation of Rakefile.rb
    * Fixes for osx and rake 0.9.1
    * Fixes #32
    * Fixes #33
    * Fixes #35
    * Fixes #36
    * make rspecs run again
    * clean up after object_dependency_spec
    * Fixes #26
    * Fixes #37
      
      rework apply_dependency_file
    * rework apply_dependency_file
      
      Fixes #37
    * Moved method from module scope to class scope as intended
    * Rake DSL now included only once and without warning
    * generator script for big project - Fixes #38
      
      generates a big project (you can choose nr of projects and max nr of files per project)
    * sync issue in the graphstream client - Fixes #40
    * ascii progressbar - Fixes #20, Fixes #39
      
      best use together with the rake flag -s
    * benchmark of the progress precalculations - Fixes #41
    * Cleanup structure of single directory builds - Fixes #7
      
      the dir output of examples/basic looks like this:
      build
      ├── exes
      │   ├── basic.exe
      │   └── debug.exe
      ├── libs
      │   ├── lib1.a
      │   ├── lib2.a
      │   └── lib2_debug.a
      └── objects
          ├── 1
          │   ├── lib1.cpp.o
          │   └── lib1.cpp.o.d
          ├── 2
          │   ├── lib2.cpp.o
          │   └── lib2.cpp.o.d
          ├── 2_debug
          │   ├── lib2.cpp.o
          │   └── lib2.cpp.o.d
          ├── basic
          │   ├── help.cpp.o
          │   ├── help.cpp.o.d
          │   ├── main.cpp.o
          │   └── main.cpp.o.d
          └── debug
              ├── help.cpp.o
              ├── help.cpp.o.d
              ├── main.cpp.o
              └── main.cpp.o.d
    * Removed unused var
    * relative output path now behaves as intended, linker string now >more correct< but order still not perfect
    * added task to choose nr of threads for build - Fixes #43
    * added task bail_on_first_error - Fixes #42
    * build socket packets only of socket is set
    * #45 dependency order for modules not correct
    * Fixes #47 Ctrl-C handling
    * Fixes #48 return value of rake
    * Added :output_dir to sourcelib and executable - Fixes #44
    * progress task does not raise if colored or progressbar is not installed - Fixes #49
    * Example for issue #10
    * Example for #34
    * Even worse example for #34 and #10
    * Fixes #48 return value of rake - hope it works now...
    * Minor fix: only the root outputdir shall be removed --> less rm commands
    * added aborttest also to invoke prerequisites - Fixes #50
    * added args again to monkey patched invoke method - Fixes #51
    * multiple include Rake::DSL causes errors
    * simplified source for roodi - #24
    * Fixed error introduced while working on #24
    * Added method to get all toolchains (lake can print out informations about toolchain settings)
    * Collect object deps for dep checking (lake)
    * Removed puts of num threads
    * roodi refactorings - Fixes #24
    * Revert "roodi refactorings - Fixes #24"
      
      commit was accidental...
      This reverts commit e92885c1615c1c3d593b54bfea2b33c7ea40a88a.
    * dont use static fields as much - Fixes #53
    * string rename - #56
    * extract method refactorings - #54
    * refactoring - make methods smaller - #54
    * polish

v_0.4.7 => v_0.4.8

    * added graphstream support
      
      javalibs, javaserver and client, rubyclient
    * used a new snapshot of gs-core, where clear works
    * added support for custom building blocks
      
      and a little bugfix: rebuilding did not work correctly
    * corrected pom of graphstream_server
    * start of error parser development
    * cleanup task manager, continued error parser, some cosmetics
    * removed task_maker
    * fixed indention
    * reverted indention fix in project.rb and Rakefile.rb
    * better warning when rubigraph not found
    * fix example for osx
    * added support for custom building blocks
      
      and a little bugfix: rebuilding did not work correctly
    * start of error parser development
    * cleanup task manager, continued error parser, some cosmetics
    * removed task_maker
    * fixed indention
    * reverted indention fix in project.rb and Rakefile.rb
    * added graphstream support
      
      javalibs, javaserver and client, rubyclient
    * tuned continuous layout of graphstream server
    * Merge branch 'graphstream'
    * removed old jars
    * added executable jar for grapgstream server
      
      java -jar target/gs-server-0.1-SNAPSHOT-jar-with-dependencies.jar
    * error parser: further dev
    * building-block cleanup:
      
      every building block has a convert_to_rake function
      less implicit state when invoking functions (less side effects)
      better debug output
      only add whole output-directory to clean task, not all created files
    * version bump

v_0.4.6 => v_0.4.7

    * suppress rubigraph loaderror
    * some rakefile cleanup, reused pkg_files from spec
    * removed one warning from gemspec
    * refactored rakefile
    * renamed spec for cxxproject_to_rake
    * minimal fixes to have specs running in osx again
    * removed debug output
    * better warning when rubigraph not found
    * fix example for osx

v_0.4.5 => v_0.4.6

    * split up gemspec
    * some docu and fixes for rspecs
    * new tests for correctly setting build dependencies,
      
      found and fixed a bug where we did not rebuild after project file changed
    * tuned spec rake task
    * added sozi presentation
    * better cleanup in rspecs
    * Bugfix: errors in prereqs of unneeded tasks, e.g. multitask, were ignored
    * Bugfix of bugfix: now failure handling should work again
    * splitted dot graph writers into severals files, moved some stuff to lake
    * corrected gemspec
    * added rspec tests for dealing with different path settings
    * updated gem version

v_0.4.4 => v_0.4.5

    * 1.8.7
    * Merge branch 'master' of github.com:marcmo/cxxproject
    * Merge branch 'master' of github.com:marcmo/cxxproject
    * added missing project files for examples
    * namespaces for exes, libs, runs
    * Merge branch 'master' of github.com:marcmo/cxxproject
    * refactoring of main task creation function in task_maker,
      
      some corrections to the readme
    * fixed missing parameter for single_souce case
    * fixed the refactoring: module building block has also sources, add defines to compiler only one. minor cosmetic stuff
    * cleaner listener interface for rake
    * cleaned up specs
    * rspec in progress...
    * rspecs for build dependencies
    * better error handling in case of wrongly specified project confi
    * Merge branch 'master' of github.com:marcmo/cxxproject
    * removed output from testdata
    * added minimal project wizard

v_0.4.3 => v_0.4.4

    * fixed deep copy, added var to change num of cores
    * flush implementation needed for 1.9.2
      
      also added some targets to work with ubigraph
    * Merge branch 'master' of https://github.com/marcmo/cxxproject
    * reformat
    * added command line bb
    * enhanced ubigraph support + bugfix for lazy FileLists
      
      see rubygraph: rake namespace
    * mainly torake changes:
      
      now possible to define multiple configurations in one cxxconfiguration (e.g. one for debug, one for release)
      updated all examples to work with toolchains instead of compiler

v_0.4.2 => v_0.4.3

    * Removed task_prerequisites-dependencies
    * graph adapted due to last change (dependencies)
    * Rakefile now works with current rspec
    * spec task will be created for current rspec version. however, specs do not run yet
    * output_path can now be absolute, some dep fixes, cleanup tabs
    * performance boost: dep file has now absolute pathnames (no convert when re-read needed)
    * cosmetic: removed wrong comment
    * performance boost: results of timestamp and needed? cached
    * performance boost: removed veeery slow pathname lib for ruby 1.8
    * bugfix: output path now works as excepted
    * nicer output, lnk errors now readable by cxxproject
    * removed accidentially added code, ruby 1.9.2 compatible
    * bugfix: c flags incorrect
    * fixed apply-enhance-break-dependencies-bug, fixed crash if file i depfile does not exist anymore, removed tabs
    * removed optimization of timestamps...
      
      caching prevented correct builds
    * added ubigraph support,
      
      bugfixes for needed? method
    * some roodi fixes and removal of unneeded function
    * reverted removal of function...is needed to display linker warnings/errors
    * added possiblity to build single files with other tcs than project
    * torake needed some additional parameters and no compiler anymore (toolchain instead)

v_0.4.1 => v_0.4.2

    * Added new folder for toolchain defs
    * first version of taskmaker
    * Added new folder for toolchain defs
    * first version of taskmaker
    * Merge branch 'master' into apichange
    * makefile handling improved
    * makfile fixes, some other fixes
    * added graph writer, moved rake_ext to cxxproiect
    * dep to proj files, multitask only for objects, read dep file only if needed, refactored internal toolchain def
    * beautifier
    * initial diab settings; mapfile; makefile fixes
    * better thread handling for multitask
    * typo, did not run correctly anymore
    * deep copy for compiler defs now working
    * fixed probs in toolchain config, makefile deps and rebuild probs, logging thread safe
    * fixed multithreaded console output, diab calcs its deps by itself - much faster (cleaned still needed)
    * Cosmetic output enhancement when error in calc dep
    * some cleanup, fixed dependency to archive and makefile tasks (rebuild too often)
    * merged alternative and master branch
    * fixed basic usecases again
    * Merge branch 'apichange'
      
      Conflicts:
      	lib/cxxproject.rb
      	lib/cxxproject/buildingblock.rb
      	lib/cxxproject/task_maker.rb
      	lib/cxxproject/toolchain/base.rb
      	lib/cxxproject/toolchain/diab.rb
      	lib/cxxproject/toolchain/gcc.rb
      	lib/cxxproject/toolchain/settings.rb
      	lib/cxxproject/torake.rb
    * removed debug puts
    * rvm setup for the needed ruby version
    * graph updates, minor fixes
    * removed obsolete files
    * graph improved, fixed some bugs
    * linking now possible with lake, removed circ dep check, outputname task, some bugfixes, improved graphs
    * bugfix: output dir created if task has no sources
    * some refactorings and renames
    * default to whole-archive linker option on gcc
      
      this is neccessary when linking c++ code where global instances register in constructors (as in cppunit)
    * refactoring name of function

v_0.4.0 => v_0.4.1

    * fixed pathname problem
    * on the way to merge in changes on apichange branch
    * new api: using task_maker instead of compiler
    * compiler toolchain is now used instead of compiler classes,
      task_maker introduces interface that takes the building-blocks and creates the tasks
    * removed old taskmaker
    * added comments and tests
      
      started to add dependendy base specs to test correct build/rebuild behavior
    * added feature: build only for collection of source files

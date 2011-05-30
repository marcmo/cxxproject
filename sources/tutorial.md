
## Tutorial

In this little tutorial we're going to walk through an example of setting up cxx-build support for a c++ project.
This is our basic scenario:
* we have a library that we want to compile and link (e.g. gtest)
* we have some source files that we need to compile and link with the gtest-library into an executable

### Basic Setup

Let's start by downloading the library that we want to build and link with:


<pre class="terminal">
  $ wget http://googletest.googlecode.com/files/gtest-1.6.0.zip
  $ unzip gtest-1.6.0.zip && rm gtest-1.6.0.zip
</pre>

Now we want to turn the library into a **source-building-block**. To do this we need a building block description for it.

<pre class="terminal">
  $ cxx .
  $ mv project.rb gtest
</pre>

In order to use the gtest library we need to compile it into 2 static libs.
Here is what the building-block description looks like after we adapted it to match our needs:


    cxx_configuration do
      source_lib "gtest",
        :sources => FileList['src/gtest-all.cc'],
        :includes => ['include','.'],
        :dependencies => []
      source_lib "gtest_main",
        :sources => FileList['src/gtest_main.cc'],
        :includes => ['include'],
        :dependencies => ["gtest"]
    end

Good. Note that we included both source libraries in the configuration file.


Now we also need to tweek the Rakefile.rb a little. We want to 
* use the gcc-toolchain
* add some additional flags

    require 'cxxproject'
    BuildDir = "BuildDir"

    unittest_flags = {
      :DEFINES => ['UNIT_TEST'],
      :FLAGS => "-O0 -g3 -Wall"
    }
    toolchain = Provider.modify_cpp_compiler("GCC", unittest_flags)
    dependent_projects =  FileList['**/project.rb']
    CxxProject2Rake.new(dependent_projects, BuildDir, toolchain, '.')

Well...looks good! Now we can check what rake tasks are generated for us:

<pre class="terminal">
  $ rake -T
  rake clean           # Remove any temporary products.
  rake clobber         # Remove any generated file.
  rake lib:gtest       # BuildDir/libgtest.a
  rake lib:gtest_main  # BuildDir/libgtest_main.a
</pre>

Let's try to build the gtest_main lib. Note that this should also build the gtest lib:

<pre class="terminal">
  $ rake lib:gtest_main
  g++ -c  -MMD -MF BuildDir/gtest/src/gtest-all.cc.o.d -O0 -g3 -Wall -Igtest-1.6.0/include -Igtest-1.6.0 -DUNIT_TEST -o BuildDir/gtest/src/gtest-all.cc.o gtest-1.6.0/src/gtest-all.cc

  ar -r BuildDir/libgtest.a BuildDir/gtest/src/gtest-all.cc.o
  ar: creating BuildDir/libgtest.a
  mkdir -p BuildDir/gtest_main/src
  g++ -c  -MMD -MF BuildDir/gtest_main/src/gtest_main.cc.o.d -O0 -g3 -Wall -Igtest-1.6.0/include -Igtest-1.6.0 -DUNIT_TEST -o BuildDir/gtest_main/src/gtest_main.cc.o gtest-1.6.0/src/gtest_main.cc

  ar -r BuildDir/libgtest_main.a BuildDir/gtest_main/src/gtest_main.cc.o
  ar: creating BuildDir/libgtest_main.a
</pre>

Nice! we got ourselfs both libraries. That was painless!
Next we want to add some code that we will end up testing using the gtest-framework.

libA/libA.h

    int a(int);

libA/libA.cpp

    #include "libA.h"

    int a(int x)
    {
        return 8*x;
    }

And of course we need a building block description for our little library:
libA/project.rb

    cxx_configuration do
      source_lib "A",
        :sources => FileList['*.cpp'],
        :includes => ['.'],
        :dependencies => []
    end

Let's see what rake will allow us to do now:

<pre class="terminal">
  $ rake -T
  rake clean           # Remove any temporary products.
  rake clobber         # Remove any generated file.
  rake lib:A           # BuildDir/libA.a
  rake lib:gtest       # BuildDir/libgtest.a
  rake lib:gtest_main  # BuildDir/libgtest_main.a
</pre>

Just a quick check if we can build our lib:

<pre class="terminal">
  $ rake lib:A
  mkdir -p BuildDir/A
  g++ -c  -MMD -MF BuildDir/A/libA.cpp.o.d -O0 -g3 -Wall -IlibA -DUNIT_TEST -o BuildDir/A/libA.cpp.o libA/libA.cpp
  ar -r BuildDir/libA.a BuildDir/A/libA.cpp.o
  ar: creating BuildDir/libA.a
</pre>

Seems to work. Now let's get down with the testing.
this will be our basic test:
libA/tests/testLibA.cpp

    #include "gtest/gtest.h"
    #include "libA.h"

    TEST(liba, function_a){
        EXPECT_EQ(8, a(1));
    }

and add a building-block-description for our executable:

    cxx_configuration do
      deps = [BinaryLibrary.new('pthread'),BinaryLibrary.new('dl')]
      exe "testme",
        :sources => FileList['**/*.cpp'],
        :includes => ['.'],
        :dependencies => ['A','gtest_main'] + deps,
        :libpath => ['../../lib']
    end

now rake will give us even more tasks:

<pre class="terminal">
    $ rake -T
    rake clean           # Remove any temporary products.
    rake clobber         # Remove any generated file.
    rake exe:testme      # BuildDir/testme.exe
    rake lib:A           # BuildDir/libA.a
    rake lib:gtest       # BuildDir/libgtest.a
    rake lib:gtest_main  # BuildDir/libgtest_main.a
    rake run:testme      # run executable BuildDir/testme.exe
</pre>

And finally we can try to build, link and run our test:

<pre class="terminal">
  $ rake run:testme
  g++ -c  -MMD -MF BuildDir/testme/testLibA.cpp.o.d -O0 -g3 -Wall -IlibA/tests -IlibA -Igtest-1.6.0/include -Igtest-1.6.0 -DUNIT_TEST -o BuildDir/testme/testLibA.cpp.o libA/tests/testLibA.cpp

  g++ -all_load -o BuildDir/testme.exe BuildDir/testme/testLibA.cpp.o -Wl,--whole-archive -Llib -LBuildDir -lA -lgtest_main -lpthread -ldl -lgtest -Wl,--no-whole-archive

  BuildDir/testme.exe
  Running main() from gtest_main.cc
  [==========] Running 1 test from 1 test case.
  [----------] Global test environment set-up.
  [----------] 1 test from liba
  [ RUN      ] liba.function_a
  [       OK ] liba.function_a (0 ms)
  [----------] 1 test from liba (0 ms total)

  [----------] Global test environment tear-down
  [==========] 1 test from 1 test case ran. (1 ms total)
  [  PASSED  ] 1 test.
</pre>

Done! now we have a test application that consists of

* 3 source libraries (gtest, gtest_main, A)
* 1 executable (testme)

with the following dependencies:

  testme => [gtest_main,A]

  gtest_main => gtest










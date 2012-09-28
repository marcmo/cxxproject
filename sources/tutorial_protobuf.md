
## Protobuf Tutorial (1)

This tutorial shows you how to get a more complex project going.
What we want to accomplish is to get the addressbook example from http://code.google.com/apis/protocolbuffers/docs/cpptutorial.html going.
We start at the desired output and let rake and cxx-project tell us what we have to do:) lets see how this works:
## Step 1
### Goals
In this step we create a directory-structure with:
* the sources from the protobuf webpage
* minimal rakefile to get going
* a cxxproject-file to get the two executables addressbook_(read|write)

### Code
    mkdir -p protobuf_cxx_example/addressbook
    cd protobuf_cxx_example
    create addressbook/addressbook_read.cc, addressbook/addressbook_write.cc and addressbook/addressbook.proto from the webpage
    please adjust the includes in the *.cc files to #include "addressbook/addressbook.pb.h"

    create addressbook/project.rb with:
    cxx_configuration do

      exe 'addressbook_write',
        :sources => ['addressbook_write.cc'],
        :dependencies => ['addressbook_pb_api']

      exe 'addressbook_read',
        :sources => ['addressbook_read.cc'],
        :dependencies => ['addressbook_pb_api']

    end
    create Rakefile.rb with:
    require 'cxxproject'
    cxx(FileList['**/project.rb'], "build", "gcc", './') do
### Explanation
in the cxx-projectfile we say, that we want to build 2 executables by giving a sourcefile and depending on the addressbook_pb_api (which will be a library created from the generated sources).
the rakefile simply collects all *project.rb files in all directories, gives build as outputdirectory for the compilation process, chooses gcc as toolchain and . as working directory.
### Next Steps
<pre class="terminal">
rake
ERROR: while reading config file for addressbook_write: dependent building block "addressbook_pb_api" was specified but not found!
</pre>
This tells us, that we have to tell cxxproject how to get addressbook_pb_api.

## Step 2
### Goals
No we have to tell cxxproject how it can build the building block addressbook_pb_api.
### Code
    add to addressbook/project.rb:
    source_lib'addressbook_pb_api',
      :sources => ['../build/protoc/addressbook/addressbook.pb.cc'],
      :includes => ['../build/protoc'],
      :dependencies => ['protobuf']
### Explanation
This tells cxxproject that the library addressbook_pb_api can be build from the source gen/addressbook/addressbook.pb.cc and that this library depends on the protobuf library
### Next Steps
<pre class="terminal">
rake
ERROR: while reading config file for addressbook_pb_api: dependent building block "protobuf" was specified but not found!
</pre>
This tells us that cxxproject does not know about a buildingblock for protobuf.

## Step 3
### Goals
We want to have a cxx-project buildingblock for the protobuf-library. To start simple this tutorial assumes, that you have installed the protobuf-dev libs (for ubuntu this means, that you should install protobuf-compiler and libprotobuf-dev).

### Code
    create protobuf_project.rb with:
    cxx_configuration do
      BinaryLibrary.new('protobuf')
    end
### Explanation
This tells cxxproject that there is a binary library (located in the default paths) for protobuf.
### Next Steps
<pre class="terminal">
rake exe:filter
Error build/build/protoc/addressbook/addressbook.pb.cc.o: Don't know how to build task 'build/protoc/addressbook/addressbook.pb.cc'
</pre>
When we now try to build all executables rake tells us, that it does not know how to build addressbook/gen/addressbook/addressbook.pb.cc.

## Step 4
### Goals
We have to kick off the protoc compiler. As cxxproject is not aware of pro
tobuf we have to define normal raketasks to get this goal.
### Code
    add to Rakefile.rb:
    PROTOC = '/usr/bin/protoc'
    GEN_FOLDER = File.join('build', 'protoc')

    directory GEN_FOLDER

    desc 'protoc addressbook.proto'
    file File.join(GEN_FOLDER, 'addressbook', 'addressbook.pb.cc') => [File.join('addressbook', 'addressbook.proto'), GEN_FOLDER, PROTOC] do
      command = "#{PROTOC} --cpp_out=#{GEN_FOLDER} #{File.join('addressbook', 'addressbook.proto')}"
      sh command
    end
### Explanation
This tells rake how to create the needed files with protoc.
### Next Steps
<pre class="terminal">
rake exe:filter
</pre>
This seems to work just fine ...
lets try it out!
<pre class="terminal">
build/addressbook_write.exe test
</pre>
Great!

## Wrap Up
This short tutorial showed you how to setup the addressbook example from protobuf. In 4 simple steps it builds two executables, using the preinstalled protobuf library on your system.
Make sure to check the accompanying git-repository@https://github.com/gizmomogwai/cxxproject_tutorials (branch protobuf_tutorial_1).

<image src="../images/tutorial_protobuf_image1.svg" width="100%"  />

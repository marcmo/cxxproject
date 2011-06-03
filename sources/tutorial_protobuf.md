
## Protobuf Tutorial

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
    create addressbook/addressbook_read.cc and addressbook/addressbook_write.cc from the webpage
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
    CxxProject2Rake.new(FileList['**/*project.rb'] , "build", GCCChain, ".")
### Explanation
in the cxx-projectfile we say, that we want to build 2 executables by giving a sourcefile and depending on the addressbook_pb_api (which will be a library created from the generated sources).
the rakefile simply collects all *project.rb files in all directories, gives build as outputdirectory for the compilation process, chooses gcc as toolchain and . as working directory.
### Next Steps
<pre class="terminal">
rake
</pre>
this tells us, that we have to tell cxxproject how to get addressbook_pb_api.

## Step 2
### Goals
No we have to tell cxxproject how it can build the building block addressbook_pb_api.
### Code
    add to addressbook/project.rb:
    source_lib 'addressbook_pb_api',
      :sources => ['gen/addressbook/addressbook.pb.cc'],
      :includes => ['gen'],
      :dependencies => ['protobuf']
### Explanation
This tells cxxproject that the library addressbook_pb_api can be build from the source gen/addressbook/addressbook.pb.cc and that this library depends on the protobuf library
### Next Steps
<pre class="terminal">
rake
</pre>
This tells us that cxxproject does not know about a buildingblock for protobuf.
## Step 3
### Goals
We want to have a cxx-project buildingblock for protobuf.
You could use your system packaging system to install protobuf (and get all libraries and the protobuf-compiler). My current system does not provide the newest protobuf version (2.4.1), so the next steps will download protobuf, configure it for the system, build protobuf libraries and protoc with make.

But to start from the end we first define a binarylib buildingblock for the protobuf library.

### Code
    add to Rakefile.rb
    PROTOBUF_VERSION='2.4.1'
    PROTOBUF_BASE="protobuf-#{PROTOBUF_VERSION}"

    create a new file protobuf_project.rb with:
    cxx_configuration do
      BinaryLibrary.new('protobuf').set_lib_searchpaths(File.join(PROTOBUF_BASE, 'tmp', 'src', 'lib'))
    end
### Explanation
This tells cxxproject that there is a prebuild library in some directory.
### Next Steps
<pre class="terminal">
rake -T
</pre>
This shows us what rake known until now. looks good, we have two executables ... lets try to build one:
<pre class="terminal">
rake exe:addressbook_write
</pre>
We see that we have now to create the protobuf files.

## Step 4
### Goals
We need to create addressbook_pb.cc. As cxxproject is not aware of protobuf and protoc we have to use normal rake tasks to get the generation process kicked off.
### Code
    add to Rakefile.rb:
    PROTOBUF_TMP = File.join(PROTOBUF_BASE, 'tmp')
    PROTOC = File.join(PROTOBUF_TMP, 'src', 'protoc')
    GEN_FOLDER = File.join('addressbook', 'gen')
    directory GEN_FOLDER
    ['addressbook.pb.cc'].each do |f|
      desc 'protoc addressbook.proto'
      file File.join(GEN_FOLDER, 'addressbook', f) => [File.join('addressbook', 'addressbook.proto'), GEN_FOLDER, PROTOC] do
        command = "#{PROTOC} --cpp_out=#{GEN_FOLDER} #{File.join('addressbook', 'addressbook.proto')}"
        sh command
      end
    end
    create file addressbook/addressbook.proto with the contents of the webpage
### Explanation
This creates a target folder for protoc and calls it with cpp_out pointing to that folder with the proto-definition. As prerequisites this task has the protofile, so the sources are regenerated everytime the file changes, the output directory and the proto-compiler itself.
### Next Steps
<pre class="terminal">
rake exe:filter
</pre>
This tries to build all executables and again it fails, because the system does not know how to derive protoc


## Step 5
### Goals
This step finally creates the tasks necessary for downloading, unpacking, configuring and compiling the protobuf-library.
### Code
    add to Rakefile.rb:
    PROTOBUF_ARCHIVE="#{PROTOBUF_BASE}.tar.gz"
    PROTOBUF_DOWNLOAD="tmp/#{PROTOBUF_ARCHIVE}"

    directory 'tmp'

    desc "download protobuf #{PROTOBUF_VERSION}"
    file PROTOBUF_DOWNLOAD => 'tmp' do
      cd 'tmp' do
        command = "wget http://protobuf.googlecode.com/files/#{PROTOBUF_ARCHIVE}"
        sh command
      end
    end

    PROTOBUF_CONFIGURE=File.join(PROTOBUF_BASE, 'configure')
    desc 'unpack protobuf'
    file PROTOBUF_CONFIGURE => PROTOBUF_DOWNLOAD do |t|
      command = "tar xf #{PROTOBUF_DOWNLOAD}"
      sh command
    end

    PROTOBUF_MAKEFILE = File.join(PROTOBUF_TMP, 'Makefile')
    directory PROTOBUF_TMP
    desc 'configure protobuf creating makefile'
    file PROTOBUF_MAKEFILE => [PROTOBUF_CONFIGURE, PROTOBUF_TMP] do
      cd PROTOBUF_TMP do
        command = '../configure'
	sh command
      end
    end

    desc 'build protoc and libraries'
    file PROTOC => [PROTOBUF_MAKEFILE] do
      cd PROTOBUF_TMP do
       command = 'make'
       sh command
      end
    end
### Explanation
This look like much .. so i will walk through the four tasks starting again at the end :)
* file PROTOC. This will build the protoc compiler by invoking make in protobuf_tmp. It depends on PROTOBUF_MAKEFILE.
* file PROTOBUF_MAKEFILE. This creates the Makefile in PROTOBUF_TMP by depending on the configure file and the tmp directory.
* file PROTOBUF_CONFIGURE. This creates the configure file by unpacking PROTOBUF_DOWNLOAD.
* file PROTOBUF_DOWNLOAD. This simply downloads the protobuf sourcearchive with wget.
### Next Steps
<pre class="terminal">
rake exe:filter
</pre>
This time a lot of work seems to be done :) Good ... in the end it fails with: No such file or directory

## Step 6
### Goals
Finally we are really close and have just to adapt the include directories be able to find the protobuf includes.
### Code
    change the binarylibrary in protobuf_project.rb to:
    BinaryLibrary.new('protobuf').set_lib_searchpaths(File.join(PROTOBUF_BASE, 'tmp', 'src', '.libs')).set_includes(File.join(PROTOBUF_BASE, 'src'))
### Explanation
This 'simply' adjusts the searchpath for the libraries to PROTOBUF_BASE/tmp/src/.libs and tells cxxproject where to search for includes for this building block.
### Next Steps
<pre class="terminal">
rake exe:filter
</pre>
This seems to work just fine ...
lets try it out!
<pre class="terminal">
build/addressbook_write.exe test
</pre>
We get build/addressbook_write.exe: error while loading shared libraries: libprotobuf.so.7: cannot open shared object file: No such file or directory because we did not install the dynamic libraries properly. Lets adjust the ld-searchpath:
<pre class="terminal">
export LD_LIBRARY_PATH=protobuf-2.4.1/tmp/src/.libs:$LD_LIBRARY_PATH
</pre>
and try again ... yes .. it works.

## Wrap Up
This kind of lenghty tutorial showed how to construct cxxproject and rake-files to build the canonical addressbook example from protobuf. As you can the most of the things you had to write had to do with downloading and building protobuf. If you fall back to the protobuf provided by your system the whole project simplifies a lot!

If you want to spare you some typing you can checkout the git repository@TODO.
The examples directory of cxxproject contains a similar usecase, only difference is, that there the protobuf-library is also used as sourcelib-buildingblock to link statically against it.

### Open Points
There are some weaknesses in the way the dependencies are drawn between the difference buildingblocks and tasks. e.g. the system does not know how to create addressbook/gen/addressbook/addressbook.pb.h if you would evilmindedly delete the file by hand. The same holds for protobuf-2.4.1/tmp/src/.libs/libprotobuf.a because there is no task for this (just PROTOC is defined).

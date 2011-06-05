$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'cxxproject'
require 'cxxproject/extensions/rake_listener_ext.rb'
require 'cxxproject/utils/cleanup'

describe Rake::Task do
  begin
    include Rake::DSL
  rescue
    puts "update rake"
  end

  it 'should fail if source of object is missing' do
    Cxxproject.cleanup_rake

    file 'test.cc' => 'compiler' do
      sh 'touch test.cc'
    end
    sl = SourceLibrary.new('testlib').set_sources(['test.cc'])
    CxxProject2Rake.new([], 'build', GCCChain)


    l = mock
    testlib = 'build/libtestlib.a'
    objects_of_testlib = 'Sources of testlib'
    testlib_build_dir = 'build/testlib'
    l.should_receive(:before_prerequisites).with(testlib)
    l.should_receive(:before_prerequisites).with(objects_of_testlib)
    l.should_receive(:before_prerequisites).with('build/testlib/test.cc.o')
    l.should_receive(:before_prerequisites).with('test.cc')

    Rake::add_listener(l)

    task = Rake::application['build/libtestlib.a']
    lambda {task.invoke}.should raise_error(RuntimeError)

    Rake::remove_listener(l)

    Cxxproject.cleanup_rake
    FileUtils.rm_rf('build')
  end


  it 'should not fail if include-dependency of object is missing' do
    Cxxproject.cleanup_rake

    file 'test.cc' => 'build' do
      sh 'touch test.cc'
    end

    sl = SourceLibrary.new('testlib').set_sources(['test.cc'])
    CxxProject2Rake.new([], 'build', GCCChain)

    task = Rake::application['build/libtestlib.a']
    obj = Rake::application['build/testlib/test.cc.o']
    obj.enhance(['test.h', 'test.hpp', 'test.H', 'test.Hpp'])

    task.invoke

    Cxxproject.cleanup_rake
    FileUtils.rm_rf('build')
    FileUtils.rm_rf('test.cc')
  end

  it 'should fail if generated headerfile is missing' do
    Cxxproject.cleanup_rake

    file 'test.h' do
      sh 'touch test.h'
    end
    file 'test.cc' => 'test.h' do
      sh 'echo "#include \"test.h\"" > test.cc'
    end

    sl = SourceLibrary.new('testlib').set_sources(['test.cc'])
    CxxProject2Rake.new([], 'build', GCCChain)

    task = Rake::application['build/libtestlib.a']
    task.invoke

    Cxxproject.cleanup_rake
    FileUtils.rm_rf('build')
    FileUtils.rm_rf('test.cc')
    FileUtils.rm_rf('test.h')
  end

end

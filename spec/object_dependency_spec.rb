$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'cxxproject'
require 'cxxproject/extensions/rake_listener_ext.rb'
require 'cxxproject/utils/cleanup'

describe Rake::Task do

  it 'should fail if source of object is missing' do
    Cxxproject.cleanup_rake

    file 'test.cc' => 'compiler' do
      sh 'touch test.cc'
    end
    sl = SourceLibrary.new('testlib').set_sources(['test.cc'])
    cxx = CxxProject2Rake.new([], 'build', GCCChain)

    task = Rake::application['build/libs/libtestlib.a']
    task.invoke
    task.failure.should eq(true)

    Cxxproject.cleanup_rake
    FileUtils.rm_rf('build')
  end


  it 'should not fail if include-dependency of object is missing' do
    Cxxproject.cleanup_rake

    File.open('test.cc', 'w') do |io|
      io.puts('#include "test.h"')
    end

    File.open('test.h', 'w') do |io|
    end

    sl = SourceLibrary.new('testlib').set_sources(['test.cc'])
    CxxProject2Rake.new([], 'build', GCCChain)

    task = Rake::application['build/libs/libtestlib.a']
    task.invoke

    task.failure.should eq(false)

    Cxxproject.cleanup_rake

    FileUtils.rm_rf('test.h')
    File.open('test.cc', 'w') do |io|
    end


    sl = SourceLibrary.new('testlib').set_sources(['test.cc'])
    CxxProject2Rake.new([], 'build', GCCChain)

    task = Rake::application['build/libs/libtestlib.a']
    task.invoke
    task.failure.should eq(false)

    Cxxproject.cleanup_rake
    FileUtils.rm_rf('test.cc')
  end

  it 'should not fail if generated headerfile is missing' do
    Cxxproject.cleanup_rake

    file 'test.h' do
      sh 'touch test.h'
    end

    file 'test.cc' => 'test.h' do |t|
      File.open(t.name, 'w') do |io|
        io.puts('#include "test.h"')
      end
    end

    sl = SourceLibrary.new('testlib').set_sources(['test.cc'])
    CxxProject2Rake.new([], 'build', GCCChain)

    task = Rake::application['build/libs/libtestlib.a']
    task.invoke
    task.failure.should eq(false)

    Cxxproject.cleanup_rake
    FileUtils.rm_rf('build')
    FileUtils.rm_rf('test.cc')
    FileUtils.rm_rf('test.h')
  end

end

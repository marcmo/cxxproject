$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'cxxproject'
require 'cxxproject/ext/rake_listener.rb'
require 'cxxproject/utils/cleanup'

describe Rake::Task do

  before(:each) do
    Rake::application.options.silent = true
    Cxxproject.cleanup_rake
  end
  after(:each) do
    Cxxproject.cleanup_rake
  end

  it 'should fail if source of object is missing' do
    file 'test.cc' => 'compiler'
    sl = SourceLibrary.new('testlib').set_sources(['test.cc'])
    cxx = CxxProject2Rake.new([], 'build', GCCChain)

    task = Rake::application['build/libs/libtestlib.a']
    task.invoke
    task.failure.should eq(true)

    FileUtils.rm_rf('build')
  end

  it 'should not fail if include-dependency of object is missing' do
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

    FileUtils.rm_rf('test.cc')
  end

  it 'should not fail if generated headerfile is missing' do
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

    FileUtils.rm_rf('build')
    FileUtils.rm_rf('test.cc')
    FileUtils.rm_rf('test.h')
  end

end

require 'spec_helper'

require 'rspec'
require 'cxxproject'
require 'cxxproject/utils/cleanup'

describe Cxxproject::BuildingBlock do

  before(:each) do
    Cxxproject::Utils.cleanup_rake
  end
  after(:each) do
    Cxxproject::Utils.cleanup_rake
  end

  it 'should build the right dependency-chain' do
    lib1 = Cxxproject::SourceLibrary.new('1')
    lib2 = Cxxproject::SourceLibrary.new('2').set_dependencies(['1'])
    lib3 = Cxxproject::SourceLibrary.new('3').set_dependencies(['1'])
    lib4 = Cxxproject::SourceLibrary.new('4').set_dependencies(['2', '3'])
    deps = lib4.all_dependencies.map { |d| d.name }
    deps.should == ['4', '2', '3', '1']
  end

  it 'should build the right dependency-chain for custom blocks' do
    lib1 = Cxxproject::SourceLibrary.new('1')
    lib2 = Cxxproject::CustomBuildingBlock.new('2').set_dependencies(['1'])
    lib3 = Cxxproject::SourceLibrary.new('3').set_dependencies(['1'])
    lib4 = Cxxproject::CustomBuildingBlock.new('4').set_dependencies(['2', '3'])
    deps = lib4.all_dependencies.map { |d| d.name }
    deps.should == ['4', '2', '3', '1']
  end

  it 'should have the right output-directory' do
    lib1 = Cxxproject::SourceLibrary.new('lib1').set_sources(['test.cc'])
    lib1.set_project_dir(File.join(Dir.pwd, 'lib1'))

    lib2 = Cxxproject::SourceLibrary.new('lib2').set_sources(['test.cc']).set_output_dir('build2')
    lib2.set_project_dir(File.join(Dir.pwd, 'lib2'))

    cxx = CxxProject2Rake.new([], 'build', GCCChain)
    cxx.prepare_block(lib1)
    cxx.prepare_block(lib2)

    lib1.output_dir.should eq(File.join(Dir.pwd, 'build'))
    lib2.output_dir.should eq(File.join(Dir.pwd, 'lib2', 'build2'))
  end

  it 'should raise exception if building block cannot be resolved' do
    expect do
      lib1 = Cxxproject::SourceLibrary.new('1').set_dependencies(['unresolved'])
      cxx = CxxProject2Rake.new([], 'build', GCCChain)
    end.to raise_exception(RuntimeError, 'Error: while reading config file for 1: dependent building block "unresolved" was specified but not found!')
  end

end

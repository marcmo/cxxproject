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

  it 'should raise an exception if no sourcefiles are matched by a pattern' do
    expect {
      lib1 = Cxxproject::SourceLibrary.new('1').set_sources(['testerle.cpp'])
    }.to raise_exception
  end

  it 'should raise an exception if no sourcefiles are given' do
    lib1 = Cxxproject::SourceLibrary.new('1')
    lib1.output_dir = 'out'
    lib1.complete_init
    expect {
      lib1.create_object_file_tasks
    }.to raise_exception
  end

  it 'should raise an exception if sourcepatterns dont match anything' do
    lib1 = Cxxproject::SourceLibrary.new('1').set_source_patterns(['*.ccc'])
    lib1.output_dir = 'out'
    lib1.complete_init
    expect {
      lib1.create_object_file_tasks
    }.to raise_exception
  end

  def dummy_toolchain
    {:COMPILER => {:CPP => {:DEFINES => [], :SOURCE_FILE_ENDINGS => {}}, :C => {:DEFINES => [], :SOURCE_FILE_ENDINGS => {}}, :ASM => {:DEFINES => [], :SOURCE_FILE_ENDINGS => {}}}}
  end
  it 'should raise an exception if a filetype is unknown' do
    sh 'touch test.ccc'
    lib1 = Cxxproject::SourceLibrary.new('1').set_tcs(dummy_toolchain).set_sources(["test.ccc"])
    lib1.output_dir = 'out'
    lib1.complete_init
    expect {
      lib1.create_object_file_tasks
    }.to raise_exception
    sh 'rm test.ccc'
  end
end

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

  it 'should be possible to define an executable without sources' do
    exe = Cxxproject::Executable.new('1')
    exe.output_dir = 'out'
    exe.complete_init
    exe.create_object_file_tasks
  end
end


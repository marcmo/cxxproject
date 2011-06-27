require 'spec_helper'

require 'cxxproject'

describe File do

  it 'should calc if a pathname is absolute' do
    File.is_absolute?('/test').should eq(true)
    File.is_absolute?('a:test').should eq(true)
    File.is_absolute?('test').should eq(false)
  end

  it 'should find a good relative directory for subdirectories' do
    File.relFromTo('src/test.c', 'a', File.join(Dir.pwd, 'b')).should eq('../a/src/test.c')
    File.relFromTo('src/test.c', 'a', File.join(Dir.pwd, 'a', 'b')).should eq('../src/test.c')
    this_dirname = Dir.pwd.split('/')[-1] # todo ... platform independent
    File.relFromTo('src/test.c', 'a', File.expand_path(File.join(Dir.pwd, '..'))).should eq(File.join(this_dirname, 'a', 'src', 'test.c'))
  end

end

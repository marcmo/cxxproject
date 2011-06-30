require 'spec_helper'
require 'cxxproject'

describe File do

  it 'should calc if a pathname is absolute' do
    File.is_absolute?('/test').should eq(true)
    File.is_absolute?('a:test').should eq(true)
    File.is_absolute?('test').should eq(false)
  end

  it 'should find a good relative directory for subdirectories' do
    File.rel_from_to_project('x/main/a', 'x/main/b').should eq('../b/')
    File.rel_from_to_project('x/main/a/b', 'x/main').should eq('../../')
    File.rel_from_to_project('x/main', 'x/main/a/b').should eq('a/b/')
    File.rel_from_to_project('x/main', 'x/main').should eq('')
    File.rel_from_to_project('x/main', nil).should eq(nil)
    File.rel_from_to_project(nil, 'x/main').should eq(nil)
    File.rel_from_to_project('x/a', 'y/b').should eq("../../y/b/")
  end
  
  it 'add prefix only if file is not absolute' do
    File.add_prefix('abc/', '/usr/local').should eq('/usr/local')
    File.add_prefix('abc/', 'nix/usr/local').should eq('abc/nix/usr/local')
    File.add_prefix('abc/', 'c:/usr/local').should eq('c:/usr/local')
    File.add_prefix('abc/', 'c:\\usr/local').should eq('c:\\usr/local')
  end

end

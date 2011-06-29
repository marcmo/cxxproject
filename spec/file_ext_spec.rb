require 'spec_helper'
require 'cxxproject'

describe File do

  it 'should calc if a pathname is absolute' do
    File.is_absolute?('/test').should eq(true)
    File.is_absolute?('a:test').should eq(true)
    File.is_absolute?('test').should eq(false)
  end

  it 'should find a good relative directory for subdirectories' do
    File.relFromToProject('x/main/a', 'x/main/b').should eq('../b/')
    File.relFromToProject('x/main/a/b', 'x/main').should eq('../../')
    File.relFromToProject('x/main', 'x/main/a/b').should eq('a/b/')
    File.relFromToProject('x/main', 'x/main').should eq('')
    File.relFromToProject('x/main', nil).should eq(nil)
    File.relFromToProject(nil, 'x/main').should eq(nil)
    File.relFromToProject('x/a', 'y/b').should eq(nil)
    File.relFromToProject('x/a', 'a').should eq(nil)
  end
  
  it 'add prefix only if file is not absolute' do
    File.addPrefix('abc/', '/usr/local').should eq('/usr/local')
    File.addPrefix('abc/', 'nix/usr/local').should eq('abc/nix/usr/local')
    File.addPrefix('abc/', 'c:/usr/local').should eq('c:/usr/local')
    File.addPrefix('abc/', 'c:\\usr/local').should eq('c:\\usr/local')
  end

end

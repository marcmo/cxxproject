require 'rspec'
require 'cxxproject/toolchain/provider'

describe Cxxproject::Toolchain::Provider do

  it 'should merge without overwrite' do
    cpp = { :DEFINE_FLAG => "-D", :COMMAND => "clang++" }
    c = { :COMMAND => "clang" }
    expected = { :DEFINE_FLAG => "-D", :COMMAND => "clang" }
    Cxxproject::Toolchain::Provider.merge(c, cpp, false).should == expected
  end

  it 'should merge two simple hashes' do
    hashA = { :a => 1, :b => 2 }
    hashB = { :a => 3, :c => 2 }
    merged = Cxxproject::Toolchain::Provider.merge(hashA, hashB)
    merged.should == { :a => 3, :b => 2, :c => 2 }
  end

  it 'should merge nested hashes' do
    hashA = { :n => { :a => 1, :b => 2 }}
    hashB = { :n => { :a => 3, :c => 2 }}
    merged = Cxxproject::Toolchain::Provider.merge(hashA, hashB)
    merged.should == { :n => { :a => 3, :b => 2, :c => 2 }}
  end

  it 'should merge multiple level nested hashes' do
    hashA = {:COMPILER => {
                :CPP => {:COMMAND => "",:DEFINE_FLAG => "",:SOURCE_FILE_ENDINGS => [".cxx", ".cpp", ".c++", ".cc", ".C"]}}}
    hashB = {:COMPILER =>
              {:CPP => { :COMMAND => "clang++", :SOURCE_FILE_ENDINGS => [".cxx", ".cpp"]}}}
    merged = Cxxproject::Toolchain::Provider.merge(hashA, hashB)
    expected = {:COMPILER =>
              {:CPP => { :COMMAND => "clang++", :DEFINE_FLAG => "", :SOURCE_FILE_ENDINGS => [".cxx", ".cpp"]}}}
    merged.should == expected
  end

end


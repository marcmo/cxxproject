require 'cxxproject/ext/rake'
describe Rake::Task do

  include Rake::DSL

  it 'should provide tags' do
    t = task "test1"
    t.tags = Set.new
  end

  it 'should provide an empty set if no tags are given' do
    t = task "test2"
    t.tags.should_not be_nil
  end

end

describe RakeFileUtils do

  it 'should be DEFAULT by default' do
    RakeFileUtils.verbose.should eq(RakeFileUtils::DEFAULT)
  end

  it 'should test to false by default' do
    (RakeFileUtils.verbose == true).should be(false)
  end

  it 'should test to true when set to true' do
    RakeFileUtils.verbose(true) do
      (RakeFileUtils.verbose == true).should be(true)
    end
    (RakeFileUtils.verbose == true).should be(false)
  end

end

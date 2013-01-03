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

require 'cxxproject/utils/deprecated'

describe Deprecated do

  before (:each) do
    @h = $stderr
    @io = StringIO.new
    $stderr = @io
    Deprecated.reset
  end

  after (:each) do
    $stderr = @h
  end

  class DeprecatedTest
    extend Deprecated
    def new_method
    end
    deprecated_alias :old_method, :new_method
  end

  it 'should output deprecated' do
    DeprecatedTest.new.old_method
    @io.string.should == "#old_method deprecated (please use #new_method)\n"
  end

  it 'should output deprecated once for each method' do
    DeprecatedTest.new.old_method
    DeprecatedTest.new.old_method
    @io.string.should == "#old_method deprecated (please use #new_method)\n"
  end
end

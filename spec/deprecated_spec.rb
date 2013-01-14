require 'cxxproject/utils/deprecated'

describe Deprecated do

  before (:each) do
    @h = $stderr
    @io = StringIO.new
    $stderr = @io
    DeprecatedTest.reset
    DeprecatedTest2.reset
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
  class DeprecatedTest2
    extend Deprecated
    def new_method
    end
    deprecated_alias :old_method, :new_method
  end

  it 'should output deprecated' do
    DeprecatedTest.new.old_method
    @io.string.should == "DeprecatedTest#old_method deprecated (please use #new_method)\n"
  end

  it 'should output deprecated once for each method' do
    DeprecatedTest.new.old_method
    DeprecatedTest.new.old_method
    @io.string.should == "DeprecatedTest#old_method deprecated (please use #new_method)\n"
  end

  it 'should output deprecated once for each method' do
    DeprecatedTest.new.old_method
    DeprecatedTest2.new.old_method
    @io.string.should == "DeprecatedTest#old_method deprecated (please use #new_method)\nDeprecatedTest2#old_method deprecated (please use #new_method)\n"
  end

end

require 'spec_helper'
require 'cxxproject/attribute_helper'

describe AttributeHelper do
  it "should provide a method that always delivers a defaultvalue" do
    class Test
      extend AttributeHelper
      lazy_attribute_with_default :test, 3
      def test=(i)
        @test = i
      end
      def direct_test_access
        return @test
      end
    end

    t = Test.new
    t.direct_test_access.should be(nil)
    t.test.should eq(3)
    t.test = 5
    t.test.should eq(5)
  end

  it 'should provide lazy attributes with defaults' do
    class Test2
      extend AttributeHelper
      lazy_attribute_with_default :test2, [1,2,3]
    end
    t = Test2.new
    t.test2.should eq([1,2,3])
  end

end

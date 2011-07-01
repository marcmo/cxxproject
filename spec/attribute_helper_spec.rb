require 'spec_helper'
require 'cxxproject/attribute_helper'

describe AttributeHelper do
  it 'should provide a method that always delivers a defaultvalue' do
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

    t1 = Test.new
    t2 = Test.new
    t1.direct_test_access.should be(nil)
    t1.test.should eq(3)
    t1.test = 5
    t1.test.should eq(5)
    t2.test.should eq(3)
  end

  it 'should provide distinct values for objects' do
    class Test
      extend AttributeHelper
      lazy_attribute_with_default :test, 3
      def test=(i)
        @test = i
      end
    end
    t1 = Test.new
    t2 = Test.new
    t1.test.should eq(t2.test)
    t1.test = 5
    t1.test.should_not eq(t2.test)
  end

  it 'should provide lazy attributes with defaults' do
    class Test2
      extend AttributeHelper
      lazy_attribute_with_default :test2, [1,2,3]
    end
    t = Test2.new
    t.test2.should eq([1,2,3])
  end

  it 'should be possible to calculate the lazt value with a function of the object' do
    class Test3
      extend AttributeHelper
      lazy_attribute_from_calculation :test, :calc_test
      def calc_test
        3
      end
    end
    t = Test3.new
    t.test.should eq(3)
  end

end

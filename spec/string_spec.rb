require 'cxxproject'

describe String do
  it 'should remove from start if matching' do
    s = "abcd"
    s.remove_from_start('abc').should == 'd'
  end
  it 'should not change the string if the start does not match' do
    "abcd".remove_from_start('z').should == 'abcd'
  end
end

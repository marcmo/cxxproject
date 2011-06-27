require 'spec_helper'

$:.unshift File.join(File.dirname(__FILE__),"..","lib")

require 'cxxproject/ide_interface'

def check_long(e, l)
  e.next.should eq(l)
  e.next.should eq(0)
  e.next.should eq(0)
  e.next.should eq(0)
end
def check_string(e, s)
  s.bytes do |i|
    e.next.should eq(i)
  end
end

describe Cxxproject::IDEInterface do

  it 'should create a correct package from an error-array' do
    ide = Cxxproject::IDEInterface.new
    error = ['filename', '10', 2, 'error']
    packet = ide.create_error_packet(error)
    e = packet.bytes
    e.next.should eq(1)
    check_long(e, 22)
    check_long(e, 8)
    check_string(e, 'filename')
    check_long(e, 10)
    e.next.should eq(2)
    check_string(e, 'error')
  end

end

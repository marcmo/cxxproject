require 'spec_helper'
require 'cxxproject/ide_interface'
require 'cxxproject/utils/utils'

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
    
    if not Cxxproject::Utils.old_ruby? # in Ruby 1.8.6 there is no bytes methods...    
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

end

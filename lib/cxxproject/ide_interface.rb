require 'cxxproject/errorparser/error_parser'

# 
# header of tcp msg from lake to eclipse:
# 1 byte = type (problem = 0x01)
# 4 bytes = length of msg
#

# 
# payload of problem type:
# 4 bytes = length filename
# x bytes = filename
# 4 bytes = linenumber
# 1 byte = severity (0..2)
# rest    = error msg
#

class IDEInterface < ErrorParser

  def initialize()
  	@socket = nil
  	@abort = false
  	@number_of_projects = 1
  	@finished_projects = 0
  end
  
  def connect(port)
    @socket = TCPSocket.new('localhost', port)
  end
  
  def disconnect()
    @socket.close if @socket
    @socket = nil
  end

  def set_errors(error_array)
  
    error_array.each do |msg|
  
    filename = msg[0]
    line_number = msg[1].to_i
    severity = msg[2]
    error_msg = msg[3]
    
    packet = ""
    packet.force_encoding("binary") if packet.respond_to?("force_encoding") # for ruby >= 1.9
    filename.force_encoding("binary") if filename.respond_to?("force_encoding") # for ruby >= 1.9
    
    error_msg.force_encoding("binary") if error_msg.respond_to?("force_encoding") # for ruby >= 1.9
    
    packet << 1 # error type
    
    packet << 0 # length (will be corrected below)
    packet << 0
    packet << 0
    packet << 0
    
    l = filename.length
    4.times { packet << (l & 0xFF); l = l >> 256 }
    packet << filename
    
    l = line_number
    4.times { packet << (l & 0xFF); l = l >> 256 }
    
    packet << (severity & 0xFF)
	
    packet << error_msg

    l = packet.length - 5
	if packet.respond_to?("setbyte")
      (1..4).each { |i| packet.setbyte(i, (l & 0xFF)); l = l >> 256 } # ruby >= 1.9
    else
      (1..4).each { |i| packet[i] = (l & 0xFF); l = l >> 256 } # ruby < 1.9 
    end
        
    @socket.write packet
    
    end
    
  end
  
  def set_number_of_projects(num)
    @number_of_projects = num
  end
  
  def reset_project_finished()
    @finished_projects = 0
  end
  
  def project_finished()
    @finished_projects = @finished_projects + 1
    # todo: send % due to progress monitor
  end
  
  
  def get_abort()
  
    if @socket
      begin
        @socket.recv_nonblock(1)
        @abort = true # currently this is the only possible input
      rescue IO::WaitReadable
      end
    end
  
  	@abort
  end
  
  def set_abort(value)
    @abort = value
  end
  
  def scan(consoleOutput)
    raise "todo"
  end
  

end
 
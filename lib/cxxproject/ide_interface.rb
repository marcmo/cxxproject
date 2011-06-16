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
    @mutex = Mutex.new
  end

  def connect(port)
    @socket = TCPSocket.new('localhost', port)
  end

  def disconnect()
    if @socket
      sleep 0.1 # hack to let ruby send all data via streams before closing
      @socket.close
      @socket = nil
    end
  end

  def write_long(packet, l)
    4.times do
      packet << (l & 0xff)
      l = l >> 8
    end
  end

  def force_encoding(s)
    s.force_encoding("binary") if s.respond_to?("force_encoding") # for ruby >= 1.9
  end

  def set_length_in_header(packet)
    l = packet.length - 5
    if packet.respond_to?("setbyte")
      (1..4).each { |i| packet.setbyte(i, (l & 0xFF)); l = l >> 8 } # ruby >= 1.9
    else
      (1..4).each { |i| packet[i] = (l & 0xFF); l = l >> 8 } # ruby < 1.9
    end
  end

  def write_string(packet, s)
    write_long(packet, s.length)
    packet << s
  end

  def set_errors(error_array)
    if @socket
      error_array.each do |msg|
        # msg = [filename, line_number, severity, error_msg] ... perhaps use hash?
        filename = msg[0]
        packet = ""
        [packet, filename, error_msg].each {|s|force_encoding(s)}

        packet << 1 # error type
        write_long(packet, 0) # length will be corrected below
        write_string(packet, filename)
        write_long(packet, msg[1].to_i)

        packet << (msg[2] & 0xFF)
        packet << msg[3] # perhaps write error_msg with length, stringdata

        set_length_in_header(packet, l)

        @mutex.synchronize { @socket.write(packet) }
      end
    end
  end

  def set_project(name)
    packet = ""
    packet.force_encoding("binary") if packet.respond_to?("force_encoding") # for ruby >= 1.9
    name.force_encoding("binary") if name.respond_to?("force_encoding") # for ruby >= 1.9

    l = name.length

    packet << 11 # name type

    packet << (l % 256)
    packet << (l / 256)
    packet << 0
    packet << 0

    packet << name

    @mutex.synchronize { @socket.write(packet) if @socket }
  end

  def set_number_of_projects(num)

    packet = ""
    packet.force_encoding("binary") if packet.respond_to?("force_encoding") # for ruby >= 1.9

    packet << 10 # num type

    packet << 2
    packet << 0
    packet << 0
    packet << 0

    packet << (num % 256)
    packet << (num / 256)

    @mutex.synchronize { @socket.write(packet) if @socket }
  end


  def get_abort()
    if @socket
      @mutex.synchronize {
        begin
          @socket.recv_nonblock(1)
          @abort = true # currently this is the only possible input
        rescue IO::WaitReadable
          # this is not an error but the default "return"-value of recv_nonblock
        end
      }
    end

    @abort
  end

  def set_abort(value)
    @abort = value
  end

end


require 'cxxproject/errorparser/error_parser'

module Cxxproject

  # header of tcp msg from lake to eclipse:
  # 1 byte = type (problem = 0x01)
  # 4 bytes = length of msg

  # payload of problem type:
  # 4 bytes = length filename
  # x bytes = filename
  # 4 bytes = linenumber
  # 1 byte = severity (0..2)
  # rest    = error msg
  class IDEInterface < ErrorParser

    def initialize()
      @socket = nil
      @abort = false
    end

    def mutex
      @mutex ||= Mutex.new
    end

    def connect(port)
      begin
        @socket = TCPSocket.new('localhost', port)
      rescue Exception => e
        puts "Error: #{e.message}"
        ExitHelper.exit(1)
      end
    end

    def disconnect()
      if @socket
        sleep 0.1 # hack to let ruby send all data via streams before closing ... strange .. perhaps this should be synchronized!
        begin
          @socket.close
        rescue Exception => e
          puts "Error: #{e.message}"
          ExitHelper.exit(1)
        end
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
          packet = create_error_packet(msg)
          begin
            mutex.synchronize { @socket.write(packet) }
          rescue Exception => e
            puts "Error: #{e.message}"            
            set_abort(true)
          end
        end
      end
    end

    def create_error_packet(msg)
      filename = msg[0]
      line_number = msg[1].to_i
      severity = msg[2]
      error_msg = msg[3]

      packet = ""
      [packet, filename, error_msg].each {|s|force_encoding(s)}

      packet << 1 # error type
      write_long(packet,0) # length (will be corrected below)

      write_string(packet, filename)
      write_long(packet,line_number)
      packet << (severity & 0xFF)
      packet << error_msg

      set_length_in_header(packet)
      packet
    end

    def set_project(name)
      packet = ""
      force_encoding(packet)
      force_encoding(name)

      l = name.length

      packet << 11 # name type

      packet << (l % 256)
      packet << (l / 256)
      packet << 0
      packet << 0

      packet << name

      begin
        mutex.synchronize { @socket.write(packet) if @socket }
      rescue Exception => e
        puts "Error: #{e.message}"            
        set_abort(true)
      end
      
    end
    
    def get_number_of_projects
      @num ||= 0
    end

    def set_number_of_projects(num)
      @num = num
    
      packet = ""
      force_encoding(packet)

      packet << 10 # num type

      packet << 2
      packet << 0
      packet << 0
      packet << 0

      packet << (num % 256)
      packet << (num / 256)

      begin
        mutex.synchronize { @socket.write(packet) if @socket }
      rescue Exception => e
        puts "Error: #{e.message}"            
        set_abort(true)
      end
      
    end

    def get_abort()
      return @abort if @abort
      if @socket
        mutex.synchronize {
          begin
            @socket.recv_nonblock(1)
            set_abort(true) # currently this is the only possible input
          rescue IO::WaitReadable
            # this is not an error but the default "return"-value of recv_nonblock
          rescue Exception => e
            puts "Error: #{e.message}"            
            set_abort(true)
          end          
        }
      end

      @abort
    end

    def set_abort(value)
      @abort = value
    end

  end
end


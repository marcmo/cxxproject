module Cxxproject

  class ProcessHelper

    def self.readOutput(sp, rd, wr)
      wr.close
        
      consoleOutput = ""
      while not rd.eof? 
        consoleOutput << rd.read_nonblock(1000)
      end
        
      Process.wait(sp)
      rd.close
      
      consoleOutput
    end

  end

end
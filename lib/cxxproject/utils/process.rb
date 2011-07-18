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
      
      # seems that pipe cannot handle non-ascii characters right on windows (even with correct encoding)  
      consoleOutput.gsub!(/\xE2\x80\x98/,"`") # ÔÇÿ
      consoleOutput.gsub!(/\xE2\x80\x99/,"'") # ÔÇÖ
      
      consoleOutput
    end

  end

end
module Cxxproject

  class ProcessHelper

    def self.readOutput(sp, rd, wr)
      wr.close
        
      consoleOutput = ""
      begin
        while not rd.eof? 
           tmp = rd.read(1000)
           if (tmp != nil)
             consoleOutput << tmp
           end  
        end
      rescue Exception=>e
        # sometimes there is a bad file descriptor on Windows instead of eof...
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
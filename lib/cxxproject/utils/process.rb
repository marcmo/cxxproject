module Cxxproject

  class ProcessHelper
    @@pid = nil

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
        # Seems to be a bug in ruby: sometimes there is a bad file descriptor on Windows instead of eof, which causes
        # an exception on read(). However, this happens not before everything is read, so there is no practical difference
        # how to "break" the loop.
        # This problem occurs on Windows command shell and Cygwin.
      end
        
      Process.wait(sp)
      rd.close
      
      # seems that pipe cannot handle non-ascii characters right on windows (even with correct encoding)  
      consoleOutput.gsub!(/\xE2\x80\x98/,"`") # ÔÇÿ
      consoleOutput.gsub!(/\xE2\x80\x99/,"'") # ÔÇÖ
      
      consoleOutput
    end

    def self.spawnProcess(cmdLine)
      return system(cmdLine) if Cxxproject::Utils.old_ruby?
      @@pid = spawn(cmdLine)
      pid, status = Process.wait2(@@pid)
      @@pid = nil
      status.success? 
    end

    def self.killProcess
      begin
        Process.kill("KILL",@@pid)
      rescue
      end
      @@pid = nil
    end
    
    def self.safeExecute
      begin
        consoleOutput = yield
        [$?.success?, consoleOutput, false]
      rescue Exception => e
        [false, e.message, true]
      end
    end
  end

end
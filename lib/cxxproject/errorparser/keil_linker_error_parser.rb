require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class KeilLinkerErrorParser < ErrorParser

    def initialize()
      @error_exclude = /Finished: [0-9]+ information, [0-9]+ warning and [0-9]+ error messages./
    end

    def scan_lines(consoleOutput, proj_dir)
      res = []
      consoleOutput.each_line do |l|
        l.rstrip!
        scan_res = l.scan(@error_exclude)
        d = ErrorDesc.new
        if scan_res.length == 0
          d.file_name = proj_dir
          d.line_number = 0
          d.message = l
          if l.length == 0
            d.severity = SEVERITY_OK
          elsif l.include?" Warning:" 
            d.severity = SEVERITY_WARNING
          else
            d.severity = SEVERITY_ERROR
          end
        end
        res << d
      end
      [res, consoleOutput]
    end


  end
end

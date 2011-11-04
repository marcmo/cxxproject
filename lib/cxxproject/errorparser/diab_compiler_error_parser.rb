require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class DiabCompilerErrorParser < ErrorParser

    def initialize()
      @error_expression_start = /\"(.+)\", line ([0-9]+): (catastrophic |fatal )*([A-Za-z]+) (.+)/  
      @error_expression_end = /^[ \t]*\^/ # well, it may end without "^"... in this case the error will last the next one starts or console text ends
    end

    def scan_lines(consoleOutput, proj_dir)
      res = []
      error_severity = 255
      consoleOutputFullnames = consoleOutput.each_line.map do |l|
        d = ErrorDesc.new
        lstripped = l.rstrip
        scan_res = lstripped.scan(@error_expression_start)
        if scan_res.length == 0
          d.severity = error_severity
          d.message = lstripped 
          if lstripped.scan(@error_expression_end).length > 0
            error_severity = 255 
          end
        else
          d.file_name = File.expand_path(scan_res[0][0])
          d.line_number = scan_res[0][1].to_i
          d.message = scan_res[0][4]
          d.severity = get_severity(scan_res[0][3])
          error_severity = d.severity
          l.gsub!(scan_res[0][0],d.file_name)
        end
        res << d
        l
      end.join
      [res, consoleOutputFullnames]
    end

  end
end

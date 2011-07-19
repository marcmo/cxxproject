require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class DiabErrorParser < ErrorParser


    def get_severity(str)
      if str == "info"
        0
      elsif str == "warning"
        1
      elsif str == "error"
        2
      else
        raise "Unknown severity: #{str}"
      end
    end

    def scan(consoleOutput, proj_dir)
      res = []
      error_severity = 255
      consoleOutput.each_line do |l|
        d = ErrorDesc.new
        scan_res = l.scan(/\"(.+)\", line ([0-9]+): [catastrophic ]*([A-Za-z]+) (.+)/)
        if scan_res.length == 0
          if error_severity != 255
            if l.start_with?("          ")
              d.severity = error_severity
              d.message = l[9..-1]
            end
          end
        else
          d.file_name = File.expand_path(scan_res[0][0])
          d.line_number = scan_res[0][1]
          d.message = scan_res[0][3]
          d.severity = get_severity(scan_res[0][2])
          error_severity = d.severity
        end
        res << d
      end
      res
    end

  end
end

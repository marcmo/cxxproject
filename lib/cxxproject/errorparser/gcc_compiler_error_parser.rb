require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class GCCCompilerErrorParser < ErrorParser

    def initialize()
      @error_expression = /(.+):([0-9]+): (catastrophic )*([A-Za-z]+): (.+)/
    end


    def scan_lines(consoleOutput, proj_dir)
      res = []
      consoleOutput.each_line do |l|
        d = ErrorDesc.new
        scan_res = l.gsub(/\r\n?/, "").scan(@error_expression)
        if scan_res.length > 0
          d.file_name = File.expand_path(scan_res[0][0])
          d.line_number = scan_res[0][1].to_i
          d.message = scan_res[0][4]
          d.severity = get_severity(scan_res[0][3])
        end
        res << d
      end
      res
    end

  end
end

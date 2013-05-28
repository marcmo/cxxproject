require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class GreenHillsLinkerErrorParser < ErrorParser

    def initialize()
      # todo: is every line an error?
    end

    def scan_lines(consoleOutput, proj_dir)
      res = []
      consoleOutput.each_line do |l|
        l.rstrip!
        d = ErrorDesc.new
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
        res << d
      end
      [res, consoleOutput]
    end

  end
end

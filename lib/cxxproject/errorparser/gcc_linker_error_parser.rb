require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class GCCLinkerErrorParser < ErrorParser

    def initialize()
      @error_expression1 = /(.*:\(\..*\)): (.*)/  # e.g. /c/Tool/Temp/ccAlar4R.o:x.cpp:(.text+0x17): undefined reference to `_a'
      @error_expression2 = /(.*):([0-9]+): (.*)/  # e.g. /usr/lib/gcc/i686-pc-cygwin/4.3.4/../../../../i686-pc-cygwin/bin/ld:roodi.yml.a:1: syntax error
    end

    # todo: how do linker warnings look like?
    # todo: are these all linker errors?
    def scan_lines(consoleOutput, proj_dir)
      res = []
      consoleOutput.each_line do |l|
        l.rstrip!
        d = ErrorDesc.new
        scan_res1 = l.scan(@error_expression1)
        scan_res2 = l.scan(@error_expression2)
        if scan_res1.length > 0
          d.file_name = scan_res1[0][0]
          d.line_number = 0
          d.message = scan_res1[0][1]
          d.severity = SEVERITY_ERROR
        elsif scan_res2.length > 0
          d.file_name = scan_res2[0][0]
          d.line_number = scan_res2[0][1].to_i
          d.message = scan_res2[0][2]
          d.severity = SEVERITY_ERROR
        end
        res << d
      end
      res  
    end


  end
end

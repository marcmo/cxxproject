require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class DiabErrorParser < ErrorParser

    def initialize(exp)
      super(exp)
    end


    def scan(consoleOutput, proj_dir)
      res = []
      consoleOutput.scan(@error_expression).each do |e|
        e[0] = File.expand_path(e[0])
        e[2] = get_severity(e[2])

        if e[4].length>10 and e[4][0..9] == "          "
          e[3] = e[3].concat(e[4][9..-1]) # error msg can be splitted into two lines (10 spaces in front if splitted)
        end
        e.pop

        res << e
      end
      res
    end



  end
end

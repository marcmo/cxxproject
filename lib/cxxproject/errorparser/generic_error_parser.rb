require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class GenericErrorParser < ErrorParser

    def scan(consoleOutput)
      res = []
      consoleOutput.scan(/\"(.+)\", line ([0-9]+): ([A-Za-z]+) (.+)[\r\n]+(.+)/).each do |e|
        e[0] = File.expand_path(e[0])

        if e[4].length>10 and e[4][0..9] == "          "
          e[3] = e[3].concat(e[4][9..-1]) # error msg can be splitted into two lines (10 spaces in front if splitted)
        end
        e.pop
        e[2] = string_to_error_code(e[2])

        res << e
      end
      res
    end

    def string_to_error_code(s)
      case s
      when 'info'
        return 0
      when 'warning'
        return 1
      when 'error'
      when 'catastrophic error'
        return 2
      else
        raise "Unknown severity: #{s}"
      end
    end
  end
end

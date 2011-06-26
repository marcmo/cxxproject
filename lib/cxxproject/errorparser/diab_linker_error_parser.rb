require 'cxxproject/errorparser/error_parser'

module Cxxproject
  class DiabLinkerErrorParser < ErrorParser

    def get_severity(str)
      if str == "info"
        0
      elsif str == "warning"
        1
      elsif str == "error" or str == "catastrophic error"
        2
      else
        raise "Unknown severity: #{str}"
      end
    end

    def scan(consoleOutput, proj_dir)
      res = []
      consoleOutput.scan(/dld: ([A-Za-z]+): (.+)/).each do |e|
        res << [
          proj_dir,
          0,
          get_severity(e[0]),
          e[1] ]
        end
      res
    end

  end
end

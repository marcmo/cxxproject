require 'cxxproject/errorparser/error_parser'

class DiabErrorParser < ErrorParser

  def getSeverity(str)
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
    consoleOutput.scan(/\"(.+)\", line ([0-9]+): [catastrophic ]*([A-Za-z]+) (.+)[\r\n]+(.+)/).each do |e|
      e[0] = File.expand_path(e[0])
      e[2] = getSeverity(e[2])

      if e[4].length>10 and e[4][0..9] == "          "
        e[3] = e[3].concat(e[4][9..-1]) # error msg can be splitted into two lines (10 spaces in front if splitted)
      end
      e.pop

      res << e
    end
    res
  end

end

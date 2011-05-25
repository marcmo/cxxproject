require 'cxxproject/errorparser/error_parser'

class DiabErrorParser < ErrorParser

  def scan(consoleOutput)
    res = []
    consoleOutput.scan(/\"(.+)\", line ([0-9]+): ([A-Za-z]+) (.+)[\r\n]+(.+)/).each do |e|
      e[0] = File.expand_path(e[0])
      
      if e[4].length>10 and e[4][0..9] == "          " 
        e[3] = e[3].concat(e[4][9..-1]) # error msg can be splitted into two lines (10 spaces in front if splitted)
      end
      e.pop
      
      if e[2] == "info"
      	e[2] = 0
      elsif e[2] == "warning"
      	e[2] = 1
      elsif e[2] == "error" or e[2] == "catastrophic error"
      	e[2] = 2
      else
        raise "Unknown severity: #{e[2]}"
      end
      
      res << e
    end
    res
  end

end
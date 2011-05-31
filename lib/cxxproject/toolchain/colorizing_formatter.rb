require 'rainbow'
class ColorizingFormatter

  FILE_PATTERN = '(.*?:\d+:\d*:? )'
  ERROR_REGEXP = Regexp.new("#{FILE_PATTERN}(error: .*)")
  WARNING_REGEXP = Regexp.new("#{FILE_PATTERN}(warning: .*)")
  RED = [255, 0, 0]
  YELLOW = [255, 255, 0]

  def format(compiler_output)
    res = ""
    compiler_output.each_line do |l|
      md = ERROR_REGEXP.match(l)
      color = RED
      if !md
        md = WARNING_REGEXP.match(l)
        color = YELLOW
      end
      if md
        res = res + md[1] + md[2].color(color) + "\n"
      else
        res = res + l
      end
    end
    res
  end
end

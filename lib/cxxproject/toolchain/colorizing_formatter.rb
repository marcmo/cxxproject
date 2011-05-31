module Cxxproject

  class ColorizingFormatter
    def initialize
      @enabled = false
    end
    
    def is_enabled
      @enabled
    end
    
  end

  begin

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
      
      def set_enable(x)
        @enabled = x
      end
      
    end
  
  rescue LoadError
  
    class ColorizingFormatter
      def set_enable(x)
        # empty
      end
    end

  end

end
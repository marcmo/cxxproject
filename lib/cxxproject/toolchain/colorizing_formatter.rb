module Cxxproject

  class ColorizingFormatter
    class << self
      attr_accessor :enabled
    end
  end

  begin
    require 'rainbow'

    # simple class to colorize compiler output
    # the class depends on the rainbow gem
    class ColorizingFormatter
      FILE_PATTERN = '(.*?:\d+:\d*:? )'
      ERROR_REGEXP = Regexp.new("#{FILE_PATTERN}(error: .*)")
      WARNING_REGEXP = Regexp.new("#{FILE_PATTERN}(warning: .*)")
      RED = [255, 0, 0]
      YELLOW = [255, 255, 0]

      # formats several lines of usually compiler output
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

      # getter to access the static variable with an instance
      def enabled?
        return ColorizingFormatter.enabled
      end
    end

  rescue LoadError

    # dont do anything if you dont have rainbow
    class ColorizingFormatter
      def enabled?
        false
      end
    end

  end

end

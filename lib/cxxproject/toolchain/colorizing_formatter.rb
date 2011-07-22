require 'cxxproject/utils/optional'

module Cxxproject
  include Utils

  class ColorizingFormatter
    class << self
      attr_accessor :enabled
    end
    def enabled?
      false
    end
  end

  define_colorizin_formatter = lambda do
    require 'colored'

    # simple class to colorize compiler output
    # the class depends on the rainbow gem
    class ColorizingFormatter

      RED = [255, 0, 0]
      YELLOW = [255, 255, 0]

      def severity_string(colors, string)
        colors[:severity].inject(string) {|m,x| m.send(x)}
      end

      def file_string(colors, string)
        colors[:file].inject(string) {|m,x| m.send(x)}
      end

      def line_string(colors, string)
        colors[:line].inject(string) {|m,x| m.send(x)}
      end
      
      def line_number_string(colors, string)
        colors[:file].inject(string) {|m,x| m.send(x)}
      end      
      
      def in_string(colors, string)
        colors[:line].inject(string) {|m,x| m.send(x)}
      end      

      def description_string(colors, string)
        colors[:description].inject(string) {|m,x| m.send(x)}
      end

      def printError(str)
        [:red,:bold].inject(str) {|m,x| m.send(x)}
      end

      def printWarning(str)
        [:yellow,:bold].inject(str) {|m,x| m.send(x)}
      end

      def printInfo(str)
        [:white,:bold].inject(str) {|m,x| m.send(x)}
      end

      def printAdditionalInfo(str)
        [:cyan,:bold].inject(str) {|m,x| m.send(x)}
      end

      def printSuccess(str)
        [:green,:bold].inject(str) {|m,x| m.send(x)}
      end


      # formats several lines of usually compiler output
      def format(compiler_output, project_dir, error_parser)
        return compiler_output if not enabled?
        res = ""
        error_descs = error_parser.scan_lines(compiler_output, project_dir)
        zipped = compiler_output.lines.zip(error_descs)
        zipped.each do |l,desc|
          if desc.severity != 255
            coloring = {}
            if desc.severity == ErrorParser::SEVERITY_WARNING
              coloring = {:file => [:yellow,:bold], :line => [:yellow], :severity => [:yellow,:bold], :description => [:yellow]}
            elsif desc.severity == ErrorParser::SEVERITY_ERROR
              coloring = {:file => [:red,:bold],    :line => [:red],    :severity => [:red,:bold],    :description => [:red]}
            else
              coloring = {:file => [:white,:bold],  :line => [:white],  :severity => [:white,:bold],  :description => [:white]}
            end
            
            if desc.file_name and desc.file_name != ""
              res << severity_string(coloring, error_parser.severity_to_str(desc.severity))
              res << in_string(coloring, " in ")
              res << file_string(coloring, "#{desc.file_name}")
              if desc.line_number and desc.line_number > 0
                res << line_string(coloring, ", line ")
                res << line_number_string(coloring, "#{desc.line_number}")
              end
              res << line_string(coloring, ": ")
            end
            
            res << description_string(coloring, "#{desc.message}") + "\n"
                        
          else
           res << l
          end
        end
        res
      end

      # getter to access the static variable with an instance
      def enabled?
        return ColorizingFormatter.enabled
      end
    end

  end

  Utils.optional_package(define_colorizin_formatter, nil)

end

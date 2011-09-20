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
    
      # colors are not instance vars due to caching the building blocks
      def self.setColorScheme(scheme)
        if scheme == :black
          @@warning_color = :yellow
          @@error_color = :red
          @@info_color = :white
          @@additional_info_color = :cyan
          @@success_color = :green
        elsif scheme == :white
          @@warning_color = :magenta
          @@error_color = :red
          @@info_color = :black
          @@additional_info_color = :blue
          @@success_color = :green
        end
      end
      ColorizingFormatter.setColorScheme(:black) # default

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
        [@@error_color,:bold].inject(str) {|m,x| m.send(x)}
      end

      def printWarning(str)
        [@@warning_color,:bold].inject(str) {|m,x| m.send(x)}
      end

      def printInfo(str)
        [@@info_color,:bold].inject(str) {|m,x| m.send(x)}
      end

      def printAdditionalInfo(str)
        [@@additional_info_color,:bold].inject(str) {|m,x| m.send(x)}
      end

      def printSuccess(str)
        [@@success_color,:bold].inject(str) {|m,x| m.send(x)}
      end


      # formats several lines of usually compiler output
      def format(compiler_output, project_dir, error_parser)
        return compiler_output if not enabled?
        res = ""
        begin
          error_descs = error_parser.scan_lines(compiler_output, project_dir)
          zipped = compiler_output.split($/).zip(error_descs)
          zipped.each do |l,desc|
            if desc.severity != 255
              coloring = {}
              if desc.severity == ErrorParser::SEVERITY_WARNING
                coloring = {:file => [@@warning_color,:bold],
                            :line => [@@warning_color],
                            :severity => [@@warning_color,:bold],
                            :description => [@@warning_color,:bold]}
              elsif desc.severity == ErrorParser::SEVERITY_ERROR
                coloring = {:file => [@@error_color,:bold],
                            :line => [@@error_color],
                            :severity => [@@error_color,:bold],
                            :description => [@@error_color,:bold]}
              else
                coloring = {:file => [@@info_color,:bold], 
                            :line => [@@info_color], 
                            :severity => [@@info_color,:bold], 
                            :description => [@@info_color,:bold]}
              end
              
              if desc.file_name and desc.file_name != ""
                res << severity_string(coloring, error_parser.severity_to_str(desc.severity))
                res << in_string(coloring, " in ")
                res << file_string(coloring, "#{desc.file_name}")
                if desc.line_number and desc.line_number > 0
                  res << line_string(coloring, " (line #{desc.line_number})")
                end
                res << line_string(coloring, ": ")
              end
              res << description_string(coloring, "#{desc.message}") + "\n"
            else
              res << l
            end
          end
        rescue Exception => e
          puts "Error while parsing compiler output: #{e}"
          return compiler_output
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

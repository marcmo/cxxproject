module Cxxproject

  class ErrorDesc
    def initialize
      @severity = 255
    end
    attr_accessor :severity
    attr_accessor :line_number
    attr_accessor :message
    attr_accessor :file_name
  end

  class ErrorParser

    SEVERITY_INFO = 0
    SEVERITY_WARNING = 1
    SEVERITY_ERROR = 2

    def initialize(exp)
      @error_expression = exp
    end

    def scan(consoleOutput, proj_dir)
      raise "Use specialized classes only"
    end

    def get_severity(str)
      if str == "info"
        SEVERITY_INFO
      elsif str == "warning"
        SEVERITY_WARNING
      elsif str == "error"
        SEVERITY_ERROR
      else
        raise "Unknown severity: #{str}"
      end
    end

    def severity_to_str(s)
      if s == SEVERITY_INFO
        "INFO"
      elsif s == SEVERITY_WARNING
        "WARNING"
      elsif s == SEVERITY_ERROR
        "ERROR"
      else
        "Unknown severity!"
      end
    end

    # scan the output from the console line by line and return a list of ErrorDesc objects.
    # for none-error/warning lines the description object will indicate that as severity 255
    # for single line errors/warnings: description will contain severity, line-number, message and file-name
    #
    # for multi-line errors/warnings:
    #   one description object for each line, first one will contain all single line error information,
    #   all following desc.objects will just repeat the severity and include the message
    #
    def scan_lines(consoleOutput)
      res = []
      error_severity = 255
      consoleOutput.each_line do |l|
        d = ErrorDesc.new
        scan_res = l.scan(@error_expression)
        if scan_res.length == 0
          if error_severity != 255
            if l.start_with?("          ")
              d.severity = error_severity
              d.message = l[9..-1]
            end
          end
        else
          d.file_name = File.expand_path(scan_res[0][0])
          d.line_number = scan_res[0][1]
          d.message = scan_res[0][3]
          d.severity = get_severity(scan_res[0][2])
          error_severity = d.severity
        end
        res << d
      end
      res
    end

  end
end

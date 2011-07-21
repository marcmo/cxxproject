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

    def scan(consoleOutput, proj_dir)
      raise "Use specialized classes only"
    end

    def get_severity(str)
      if str == "info" || str == "note"
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

    # TODO: move and adapt comment
    #
    # scan the output from the console line by line and return a list of ErrorDesc objects.
    # for none-error/warning lines the description object will indicate that as severity 255
    # for single line errors/warnings: description will contain severity, line-number, message and file-name
    #
    # for multi-line errors/warnings:
    #   one description object for each line, first one will contain all single line error information,
    #   all following desc.objects will just repeat the severity and include the message
    #
    def scan_lines(consoleOutput, proj_dir)
      raise "Use specialized classes only"
    end

    # to be removed after ide_interface refac
    def scan(consoleOutput, proj_dir)
      return []
    end

  end
end

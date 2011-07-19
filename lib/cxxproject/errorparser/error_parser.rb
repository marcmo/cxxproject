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

    def scan(consoleOutput, proj_dir)
      raise "Use specialized classes only"
    end

  end
end

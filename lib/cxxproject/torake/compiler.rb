
class Compiler
  attr_reader :output_path

  def initialize(output_path)
    @output_path = output_path
    CLOBBER.include(output_path)
  end

end

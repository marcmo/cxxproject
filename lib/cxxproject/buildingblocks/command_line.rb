require 'cxxproject/buildingblocks/building_block'

class CommandLine < BuildingBlock

  def set_command_line(x)
    @line = x
    self
  end

  def get_command_line
    @line
  end

  def get_target
    @target
  end

  def set_defined_in_file(x)
    @defined_in = x
    self
  end
  
  def get_defined_in_file
    @defined_in
  end

  @@command_line_num = 0
  def initialize(name)
    super(name)
    @line = name
    @@command_line_num = @@command_line_num + 1
    @num = @@command_line_num
  end

  def get_task_name()
    "command line (#{@num}): " + get_command_line
  end

  def convert_to_rake()
    res = task get_task_name do
      cmd = get_command_line
      puts cmd
      consoleOutput = `#{cmd + " 2>&1"}`
      process_console_output(consoleOutput)
      raise "System command failed" if $?.to_i != 0
    end
    res.transparent_timestamp = true
    setup_cleantask
    setup_rake_dependencies(res)
    res
  end

  def process_console_output(consoleOutput)
    if not consoleOutput.empty?
      puts consoleOutput

      if BuildingBlock.idei and $?.to_i != 0
        res = []
        res << (@defined_in ? @defined_in : @project_dir)
        res << 0
        res << 2
        res << "Command \"#{get_command_line}\" failed" 
        BuildingBlock.idei.set_errors([res])
      end
    end
  end

end

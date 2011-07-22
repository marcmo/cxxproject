require 'cxxproject/buildingblocks/building_block'
module Cxxproject

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

    def initialize(name)
      @line = name
      @num = Rake.application.command_line_number
      super(get_task_name)
    end

    def get_task_name()
      "command line (#{@num}): " + get_command_line
    end

    def convert_to_rake()
      res = task get_task_name do
        Dir.chdir(@project_dir) do      
          cmd = get_command_line
          consoleOutput = catch_output(cmd)
          process_result(cmd, consoleOutput)
        end
      end
      res.transparent_timestamp = true
      res.type = Rake::Task::COMMANDLINE
      setup_rake_dependencies(res)
      res
    end

    def process_console_output(consoleOutput, errorParser)
      if not consoleOutput.empty?
        puts consoleOutput

        if Rake.application.idei and $?.to_i != 0
          res = []
          res << (@defined_in ? @defined_in : @project_dir)
          res << 0
          res << 2
          res << "Command \"#{get_command_line}\" failed"
          Rake.application.idei.set_errors([res])
        end
      end
    end

  end
end

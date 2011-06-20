class Executable
  def run_command(task, command)
    require 'open3'
    stdin, stdout, stderr = Open3.popen3(command)
    puts "StdOut:"
    puts stdout.readlines
    puts "StdErr:"
    puts stderr.readlines
  end
end

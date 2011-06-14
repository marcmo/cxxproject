class ProgressHelper

  attr_reader :todo
  attr_reader :needed_tasks

  def initialize
    @todo = 0.0
    @needed_tasks = {}
  end
  def count(task)
    c = task.progress_count
    if c && c > 0
      if task.needed? && @needed_tasks[task.name] == nil
        @needed_tasks[task.name] = true
        @todo += c
      end
    end
    task.prerequisite_tasks.each do |t|
      count(t)
    end
  end
end

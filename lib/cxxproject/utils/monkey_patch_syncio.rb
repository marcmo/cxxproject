module Rake
  class SyncStringIO
    def sync_flush
      $log.error "new sync_flush setting output_string for #{for_task} to #{string}"
      Rake::Task[@for_task].output_string = string
    end
  end
  class Task
    attr_accessor :output_string
  end
end

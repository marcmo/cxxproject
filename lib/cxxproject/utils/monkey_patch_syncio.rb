module Rake
  $log.error "patching rake"
  class SyncStringIO
    def sync_flush
      $log.error "new sync_flush " if $log
      Rake::Task[@for_task].output_string = string
    end
  end
  class Task
    attr_accessor :output_string
  end
end

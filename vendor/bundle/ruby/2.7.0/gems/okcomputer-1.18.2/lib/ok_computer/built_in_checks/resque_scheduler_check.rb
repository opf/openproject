module OkComputer
  class ResqueSchedulerCheck < Check
    def check
      if working?
        mark_message 'Resque Scheduler is UP'
      else
        mark_failure
        mark_message 'Resque Scheduler is DOWN'
      end
    end

    def working?
      Resque.keys.any?{|k| k == 'resque_scheduler_master_lock'}
    end
  end
end

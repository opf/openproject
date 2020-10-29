module OkComputer
  class ResqueDownCheck < Check
    # Public: Check whether Resque workers are working
    def check
      if queued? and not working?
        mark_failure
        mark_message "Resque is DOWN. No workers are working the queue."
      else
        mark_message "Resque is working"
      end
    end

    # Public: Whether the given Resque queue has jobs
    #
    # Returns a Boolean
    def queued?
      Resque.info.fetch(:pending) > 10
    end

    # Public: Whether the Resque has workers working on a job
    #
    # Returns a Boolean
    def working?
      Resque.info.fetch(:working) > 0
    end
  end
end

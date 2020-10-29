require 'timeout'

module Delayed
  class WorkerTimeout < Timeout::Error
    def message
      seconds = Delayed::Worker.max_run_time.to_i
      "#{super} (Delayed::Worker.max_run_time is only #{seconds} second#{seconds == 1 ? '' : 's'})"
    end
  end

  class FatalBackendError < RuntimeError; end
end

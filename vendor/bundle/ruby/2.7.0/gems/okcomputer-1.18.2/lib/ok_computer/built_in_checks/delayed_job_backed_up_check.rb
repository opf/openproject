module OkComputer
  class DelayedJobBackedUpCheck < SizeThresholdCheck
    attr_accessor :priority,
                  :threshold,
                  :queue,
                  :include_locked,
                  :include_errored,
                  :greater_than_priority

    # Public: Initialize a check for backed-up Delayed Job jobs
    #
    # priority - Which priority to check for
    # threshold - An Integer to compare the jobs count against to consider it backed up
    # options - Hash of optional parameters
    #    queue - Used to monitor a specific delayed job queue (default: nil)
    #    include_locked - If true, will include currently locked jobs in the query (default: false)
    #    include_errored - If true, will include currently errored jobs in the query (default: false)
    #    greater_than_priority - If true, will include all jobs with a priority value equal or greater than the set value.
    #
    # Example:
    #   check = new(10, 50)
    #   # => The check will look for jobs with priority between
    #   # 0 and 10, considering the jobs as backed up if there
    #   # are more than 50 of them
    def initialize(priority, threshold, options = {})
      self.priority = Integer(priority)
      self.threshold = Integer(threshold)
      self.queue = options[:queue]
      self.include_locked = !!options[:include_locked]
      self.include_errored = !!options[:include_errored]
      self.greater_than_priority = !!options[:greater_than_priority]
      self.name = greater_than_priority ? "Delayed Jobs with priority higher than '#{priority}'" : "Delayed Jobs with priority lower than '#{priority}'"
    end

    # Public: How many delayed jobs are pending within the given priority
    def size
      if defined?(::Delayed::Backend::Mongoid::Job) && Delayed::Worker.backend == Delayed::Backend::Mongoid::Job
        query = greater_than_priority ? Delayed::Job.gte(priority: priority) : Delayed::Job.lte(priority: priority)
      else
        operator = greater_than_priority ? ">=" : "<="
        query = Delayed::Job.where("priority #{operator} ?", priority)
      end
      opts = {}
      opts[:queue] = queue if queue
      opts[:locked_at] = nil unless include_locked
      opts[:last_error] = nil unless include_errored
      query.where(opts).count
    end
  end
end

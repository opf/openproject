module OkComputer
  class SizeThresholdCheck < Check
    attr_accessor :size_proc
    attr_accessor :threshold
    attr_accessor :name

    # Public: Initialize a check for a backed-up Resque queue
    #
    # name -  the value that this check should be refered to as
    # threshold - An Integer to compare the size object's count against to consider
    #   it backed up
    # size_proc - The block/proc that returns an integer to compare against
    #
    # Examples
    #
    #    SizeThresholdCheck.new("some queue", 2) do
    #      Queue.new("my_queue").size
    #    end
    #
    def initialize(name, threshold, &size_proc)
      self.size_proc = size_proc
      self.threshold = Integer(threshold)
      self.name = name
    end

    # Public: Check whether the given queue is backed up
    def check
      # Memoize size here to prevent a theoretically
      # expensive operation from happening more than once
      size = self.size
      if size <= threshold
        mark_message "#{name} at reasonable level (#{size})"
      else
        mark_failure
        mark_message "#{name} is #{size - threshold} over threshold! (#{size})"
      end
    rescue ArgumentError, TypeError => e
      mark_failure
      mark_message "The given proc MUST return a number (#{e.class})"
    rescue StandardError => e
      mark_failure
      mark_message "An error occurred: '#{e.message}' (#{e.class})"
    end

    # Public: The number of jobs in the check's queue
    def size
      Integer(size_proc.call)
    end
  end
end

module OkComputer
  class ResqueFailureThresholdCheck < SizeThresholdCheck
    attr_accessor :threshold

    # Public: Initialize a check for a backed-up Resque queue
    #
    # threshold - An Integer to compare the queue's count against to consider
    #   it backed up
    def initialize(threshold)
      self.threshold = Integer(threshold)
      self.name = "Resque Failed Jobs"
    end

    # Public: The number of jobs in the check's queue
    def size
      Resque::Failure.count
    end
  end
end

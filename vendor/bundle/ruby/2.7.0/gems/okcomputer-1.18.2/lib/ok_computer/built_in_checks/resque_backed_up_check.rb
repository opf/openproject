module OkComputer
  class ResqueBackedUpCheck < SizeThresholdCheck
    attr_accessor :queue
    attr_accessor :threshold

    # Public: Initialize a check for a backed-up Resque queue
    #
    # queue - The name of the Resque queue to check
    # threshold - An Integer to compare the queue's count against to consider
    #   it backed up
    def initialize(queue, threshold)
      self.queue = queue
      self.threshold = Integer(threshold)
      self.name = "Resque queue '#{queue}'"
    end

    # Public: The number of jobs in the check's queue
    def size
      Resque.size(queue)
    end
  end
end

begin
  require 'sidekiq/api'
rescue LoadError
end

module OkComputer
  class SidekiqLatencyCheck < SizeThresholdCheck
    attr_accessor :queue

    # Public: Initialize a check for a backed-up Sidekiq queue
    # See https://github.com/mperham/sidekiq/wiki/Monitoring#monitoring-queue-latency
    #
    # queue - The name of the Sidekiq queue to check
    # threshold - An Integer to compare the queue's latency against to consider
    #   it backed up
    def initialize(queue, threshold = 30)
      self.queue = queue
      self.name = "Sidekiq queue '#{queue}' latency"
      self.threshold = Integer(threshold)
    end

    # Public: The latency of the check's queue (in seconds)
    def size
      Sidekiq::Queue.new(queue).latency
    end
  end
end

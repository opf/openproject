module Airbrake
  # Queue represents a queue (worker).
  #
  # @see Airbrake.notify_queue
  # @api public
  # @since v4.9.0
  class Queue
    include HashKeyable
    include Ignorable
    include Stashable

    attr_accessor :queue, :error_count, :groups, :timing, :time

    def initialize(
      queue:,
      error_count:,
      groups: {},
      timing: nil,
      time: Time.now
    )
      @time_utc = TimeTruncate.utc_truncate_minutes(time)
      @queue = queue
      @error_count = error_count
      @groups = groups
      @timing = timing
      @time = time
    end

    def destination
      'queues-stats'
    end

    def cargo
      'queues'
    end

    def to_h
      {
        'queue' => queue,
        'errorCount' => error_count,
        'time' => @time_utc,
      }
    end

    def hash
      {
        'queue' => queue,
        'time' => @time_utc,
      }.hash
    end

    def merge(other)
      self.error_count += other.error_count
    end

    # Queues don't have routes, but we want to define this to make sure our
    # filter API is consistent (other models define this property)
    #
    # @return [String] empty route
    # @see https://github.com/airbrake/airbrake-ruby/pull/537
    def route
      ''
    end
  end
end

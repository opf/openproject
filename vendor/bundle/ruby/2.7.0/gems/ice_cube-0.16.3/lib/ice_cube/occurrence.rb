require 'delegate'

module IceCube

  # Wraps start_time and end_time in a single concept concerning the duration.
  # This delegates to the enclosed start_time so it behaves like a normal Time
  # in almost all situations, however:
  #
  # Without ActiveSupport, it's necessary to cast the occurrence using
  # +#to_time+ before doing arithmetic, else Time will try to subtract it
  # using +#to_i+ and return a new time instead.
  #
  #     Time.now - Occurrence.new(start_time) # => 1970-01-01 01:00:00
  #     Time.now - Occurrence.new(start_time).to_time # => 3600
  #
  # When ActiveSupport::Time core extensions are loaded, it's possible to
  # subtract an Occurrence object directly from a Time to get the difference:
  #
  #     Time.now - Occurrence.new(start_time) # => 3600
  #
  class Occurrence < SimpleDelegator
    include Comparable

    # Report class name as 'Time' to thwart type checking.
    def self.name
      'Time'
    end

    attr_reader :start_time, :end_time
    alias first start_time
    alias last end_time

    def initialize(start_time, end_time=nil)
      @start_time = start_time
      @end_time = end_time || start_time
      __setobj__ @start_time
    end

    def to_i
      @start_time.to_i
    end

    def <=>(other)
      @start_time <=> other
    end

    def is_a?(klass)
      klass == ::Time || super
    end
    alias_method :kind_of?, :is_a?

    def intersects?(other)
      return cover?(other) unless other.is_a?(Occurrence) || other.is_a?(Range)

      this_start  = first + 1
      this_end    = last # exclude end boundary
      other_start = other.first + 1
      other_end   = other.last + 1

      !(this_end < other_start || this_start > other_end)
    end

    def cover?(other)
      to_range.cover?(other)
    end
    alias_method :include?, :cover?

    def comparable_time
      start_time
    end

    def duration
      end_time - start_time
    end

    def to_range
      start_time..end_time
    end

    def to_time
      start_time
    end

    # Shows both the start and end time if there is a duration.
    # Optional format argument (e.g. :long, :short) supports Rails
    # time formats and is only used when ActiveSupport is available.
    #
    def to_s(format=nil)
      if format && to_time.public_method(:to_s).arity != 0
        t0, t1 = start_time.to_s(format), end_time.to_s(format)
      else
        t0, t1 = start_time.to_s, end_time.to_s
      end
      duration > 0 ? "#{t0} - #{t1}" : t0
    end

    def overnight?
      offset = start_time + 3600 * 24
      midnight = Time.new(offset.year, offset.month, offset.day)
      midnight < end_time
    end
  end
end

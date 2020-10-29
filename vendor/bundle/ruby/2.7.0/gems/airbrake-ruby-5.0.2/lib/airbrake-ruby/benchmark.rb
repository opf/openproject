module Airbrake
  # Benchmark benchmarks Ruby code.
  #
  # @since v4.2.4
  # @api public
  class Benchmark
    # Measures monotonic time for the given operation.
    #
    # @yieldreturn [void]
    def self.measure
      benchmark = new

      yield

      benchmark.stop
      benchmark.duration
    end

    # @return [Float]
    attr_reader :duration

    # @since v4.3.0
    def initialize
      @start = MonotonicTime.time_in_ms
      @duration = 0.0
    end

    # Stops the benchmark and stores `duration`.
    #
    # @since v4.3.0
    # @return [Boolean] true for the first invocation, false in all other cases
    def stop
      return false if @duration > 0.0

      @duration = MonotonicTime.time_in_ms - @start
      true
    end
  end
end

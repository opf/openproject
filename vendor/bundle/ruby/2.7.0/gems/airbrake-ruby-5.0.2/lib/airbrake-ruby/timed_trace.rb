module Airbrake
  # TimedTrace represents a chunk of code performance of which was measured and
  # stored under a label. The chunk is called a "span".
  #
  # @example
  #   timed_trace = TimedTrace.new
  #   timed_trace.span('http request') do
  #     http.get('example.com')
  #   end
  #   timed_trace.spans #=> { 'http request' => 0.123 }
  #
  # @api public
  # @since v4.3.0
  class TimedTrace
    # @param [String] label
    # @return [Airbrake::TimedTrace]
    def self.span(label, &block)
      new.tap { |timed_trace| timed_trace.span(label, &block) }
    end

    def initialize
      @spans = {}
    end

    # @param [String] label
    # @return [Boolean]
    def span(label)
      start_span(label)
      yield
      stop_span(label)
    end

    # @param [String] label
    # @return [Boolean]
    def start_span(label)
      return false if @spans.key?(label)

      @spans[label] = Airbrake::Benchmark.new
      true
    end

    # @param [String] label
    # @return [Boolean]
    def stop_span(label)
      return false unless @spans.key?(label)

      @spans[label].stop
      true
    end

    # @return [Hash<String=>Float>]
    def spans
      @spans.each_with_object({}) do |(label, benchmark), new_spans|
        new_spans[label] = benchmark.duration
      end
    end
  end
end

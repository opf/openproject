require 'base64'

module Airbrake
  # Stat is a data structure that allows accumulating performance data (route
  # performance, SQL query performance and such). It's powered by TDigests.
  #
  # Usually, one Stat corresponds to one resource (route or query,
  # etc.). Incrementing a stat means pushing new performance statistics.
  #
  # @example
  #   stat = Airbrake::Stat.new
  #   stat.increment_ms(2000)
  #   stat.to_h # Pack and serialize data so it can be transmitted.
  #
  # @since v3.2.0
  class Stat
    attr_accessor :sum, :sumsq, :tdigest

    # @param [Float] sum The sum of duration in milliseconds
    # @param [Float] sumsq The squared sum of duration in milliseconds
    # @param [TDigest::TDigest] tdigest Packed durations. By default,
    #   compression is 20
    def initialize(sum: 0.0, sumsq: 0.0, tdigest: TDigest.new(0.05))
      @sum = sum
      @sumsq = sumsq
      @tdigest = tdigest
      @mutex = Mutex.new
    end

    # @return [Hash{String=>Object}] stats as a hash with compressed TDigest
    #   (serialized as base64)
    def to_h
      @mutex.synchronize do
        tdigest.compress!
        {
          'count' => tdigest.size,
          'sum' => sum,
          'sumsq' => sumsq,
          'tdigest' => Base64.strict_encode64(tdigest.as_small_bytes),
        }
      end
    end

    # Increments tdigest timings and updates tdigest with given +ms+ value.
    #
    # @param [Float] ms
    # @return [void]
    def increment_ms(ms)
      @mutex.synchronize do
        self.sum += ms
        self.sumsq += ms * ms

        tdigest.push(ms)
      end
    end

    # We define custom inspect so that we weed out uninformative TDigest, which
    # is also very slow to dump when we log Airbrake::Stat.
    #
    # @return [String]
    def inspect
      "#<struct Airbrake::Stat count=#{tdigest.size}, sum=#{sum}, sumsq=#{sumsq}>"
    end
    alias pretty_print inspect
  end
end

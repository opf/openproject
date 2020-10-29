require 'rbtree'

module Airbrake
  # Ruby implementation of Ted Dunning's t-digest data structure.
  #
  # This implementation is imported from https://github.com/castle/tdigest with
  # custom modifications. Huge thanks to Castle for the implementation :beer:
  #
  # The difference is that we pack with Big Endian (unlike Native Endian in
  # Castle's version). Our backend does not permit little endian.
  #
  # @see https://github.com/tdunning/t-digest
  # @see https://github.com/castle/tdigest
  # @api private
  # @since v3.2.0
  #
  # rubocop:disable Metrics/ClassLength
  class TDigest
    VERBOSE_ENCODING = 1
    SMALL_ENCODING   = 2

    # Centroid represents a number of data points.
    # @api private
    # @since v3.2.0
    class Centroid
      attr_accessor :mean, :n, :cumn, :mean_cumn
      def initialize(mean, n, cumn, mean_cumn = nil)
        @mean      = mean
        @n         = n
        @cumn      = cumn
        @mean_cumn = mean_cumn
      end

      def as_json(_ = nil)
        { m: mean, n: n }
      end
    end

    attr_accessor :centroids
    attr_reader :size

    def initialize(delta = 0.01, k = 25, cx = 1.1)
      @delta = delta
      @k = k
      @cx = cx
      @centroids = RBTree.new
      @size = 0
      @last_cumulate = 0
    end

    def +(other)
      # Uses delta, k and cx from the caller
      t = self.class.new(@delta, @k, @cx)
      data = centroids.values + other.centroids.values
      t.push_centroid(data.delete_at(rand(data.length))) while data.any?
      t
    end

    def as_bytes
      # compression as defined by Java implementation
      size = @centroids.size
      output = [VERBOSE_ENCODING, compression, size]
      output += @centroids.each_value.map(&:mean)
      output += @centroids.each_value.map(&:n)
      output.pack("NGNG#{size}N#{size}")
    end

    # rubocop:disable Metrics/AbcSize
    def as_small_bytes
      size = @centroids.size
      output = [self.class::SMALL_ENCODING, compression, size]
      x = 0
      # delta encoding allows saving 4-bytes floats
      mean_arr = @centroids.each_value.map do |c|
        val = c.mean - x
        x = c.mean
        val
      end
      output += mean_arr
      # Variable length encoding of numbers
      c_arr = @centroids.each_value.each_with_object([]) do |c, arr|
        k = 0
        n = c.n
        while n < 0 || n > 0x7f
          b = 0x80 | (0x7f & n)
          arr << b
          n = n >> 7
          k += 1
          raise 'Unreasonable large number' if k > 6
        end
        arr << n
      end
      output += c_arr
      output.pack("NGNg#{size}C#{size}")
    end
    # rubocop:enable Metrics/AbcSize

    def as_json(_ = nil)
      @centroids.each_value.map(&:as_json)
    end

    def bound_mean(x)
      upper = @centroids.upper_bound(x)
      lower = @centroids.lower_bound(x)
      [lower[1], upper[1]]
    end

    def bound_mean_cumn(cumn)
      last_c = nil
      bounds = []
      @centroids.each_value do |v|
        if v.mean_cumn == cumn
          bounds << v
          break
        elsif v.mean_cumn > cumn
          bounds << last_c
          bounds << v
          break
        else
          last_c = v
        end
      end
      # If still no results, pick lagging value if any
      bounds << last_c if bounds.empty? && !last_c.nil?

      bounds
    end

    def compress!
      points = to_a
      reset!
      push_centroid(points.shuffle)
      _cumulate(true, true)
      nil
    end

    def compression
      1 / @delta
    end

    def find_nearest(x)
      return if size == 0

      upper_key, upper = @centroids.upper_bound(x)
      lower_key, lower = @centroids.lower_bound(x)
      return lower unless upper_key
      return upper unless lower_key

      if (lower_key - x).abs < (upper_key - x).abs
        lower
      else
        upper
      end
    end

    def merge!(other)
      push_centroid(other.centroids.values.shuffle)
      self
    end

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def p_rank(x)
      is_array = x.is_a? Array
      x = [x] unless is_array

      min = @centroids.first
      max = @centroids.last

      x.map! do |item|
        if size == 0
          nil
        elsif item < min[1].mean
          0.0
        elsif item > max[1].mean
          1.0
        else
          _cumulate(true)
          bound = bound_mean(item)
          lower, upper = bound
          mean_cumn = lower.mean_cumn
          if lower != upper
            mean_cumn += (item - lower.mean) * (upper.mean_cumn - lower.mean_cumn) \
              / (upper.mean - lower.mean)
          end
          mean_cumn / @size
        end
      end
      is_array ? x : x.first
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/AbcSize
    # rubocop:enable Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/AbcSize
    def percentile(p)
      is_array = p.is_a? Array
      p = [p] unless is_array
      p.map! do |item|
        unless (0..1).cover?(item)
          raise ArgumentError, "p should be in [0,1], got #{item}"
        end

        if size == 0
          nil
        else
          _cumulate(true)
          h = @size * item
          lower, upper = bound_mean_cumn(h)
          if lower.nil? && upper.nil?
            nil
          elsif upper == lower || lower.nil? || upper.nil?
            (lower || upper).mean
          elsif h == lower.mean_cumn
            lower.mean
          else
            upper.mean
          end
        end
      end
      is_array ? p : p.first
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/AbcSize

    def push(x, n = 1)
      x = [x] unless x.is_a? Array
      x.each { |value| _digest(value, n) }
    end

    def push_centroid(c)
      c = [c] unless c.is_a? Array
      c.each { |centroid| _digest(centroid.mean, centroid.n) }
    end

    def reset!
      @centroids.clear
      @size = 0
      @last_cumulate = 0
    end

    def to_a
      @centroids.each_value.to_a
    end

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize
    def self.from_bytes(bytes)
      format, compression, size = bytes.unpack('NGN')
      tdigest = new(1 / compression)

      start_idx = 16 # after header
      case format
      when VERBOSE_ENCODING
        array = bytes[start_idx..-1].unpack("G#{size}N#{size}")
        means, counts = array.each_slice(size).to_a if array.any?
      when SMALL_ENCODING
        means = bytes[start_idx..(start_idx + 4 * size)].unpack("g#{size}")
        # Decode delta encoding of means
        x = 0
        means.map! do |m|
          m += x
          x = m
          m
        end
        counts_bytes = bytes[(start_idx + 4 * size)..-1].unpack('C*')
        counts = []
        # Decode variable length integer bytes
        size.times do
          v = counts_bytes.shift
          z = 0x7f & v
          shift = 7
          while (v & 0x80) != 0
            raise 'Shift too large in decode' if shift > 28

            v = counts_bytes.shift || 0
            z += (v & 0x7f) << shift
            shift += 7
          end
          counts << z
        end
        # This shouldn't happen
        raise 'Mismatch' unless counts.size == means.size
      else
        raise 'Unknown compression format'
      end

      means.zip(counts).each { |val| tdigest.push(val[0], val[1]) } if means && counts

      tdigest
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize

    def self.from_json(array)
      tdigest = new
      # Handle both string and symbol keys
      array.each { |a| tdigest.push(a['m'] || a[:m], a['n'] || a[:n]) }
      tdigest
    end

    private

    def _add_weight(centroid, x, n)
      unless x == centroid.mean
        centroid.mean += n * (x - centroid.mean) / (centroid.n + n)
      end

      _cumulate(false, true) if centroid.mean_cumn.nil?

      centroid.cumn += n
      centroid.mean_cumn += n / 2.0
      centroid.n += n
    end

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def _cumulate(exact = false, force = false)
      unless force
        factor = if @last_cumulate == 0
                   Float::INFINITY
                 else
                   (@size.to_f / @last_cumulate)
                 end
        return if @size == @last_cumulate || (!exact && @cx && @cx > factor)
      end

      cumn = 0
      @centroids.each_value do |c|
        c.mean_cumn = cumn + c.n / 2.0
        cumn = c.cumn = cumn + c.n
      end
      @size = @last_cumulate = cumn
      nil
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity

    # rubocop:disable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/AbcSize
    def _digest(x, n)
      # Use 'first' and 'last' instead of min/max because of performance reasons
      # This works because RBTree is sorted
      min = min.last if (min = @centroids.first)
      max = max.last if (max = @centroids.last)
      nearest = find_nearest(x)

      @size += n

      if nearest && nearest.mean == x
        _add_weight(nearest, x, n)
      elsif nearest == min
        @centroids[x] = Centroid.new(x, n, 0)
      elsif nearest == max
        @centroids[x] = Centroid.new(x, n, @size)
      else
        p = nearest.mean_cumn.to_f / @size
        max_n = (4 * @size * @delta * p * (1 - p)).floor
        if max_n - nearest.n >= n
          _add_weight(nearest, x, n)
        else
          @centroids[x] = Centroid.new(x, n, nearest.cumn)
        end
      end

      _cumulate(false)

      # If the number of centroids has grown to a very large size,
      # it may be due to values being inserted in sorted order.
      # We combat that by replaying the centroids in random order,
      # which is what compress! does
      compress! if @centroids.size > (@k / @delta)

      nil
    end
    # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity,
    # rubocop:enable Metrics/AbcSize
  end
  # rubocop:enable Metrics/ClassLength
end

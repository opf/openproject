module Airbrake
  # This class is responsible for truncation of too big objects. Mainly, you
  # should use it for simple objects such as strings, hashes, & arrays.
  #
  # @api private
  # @since v1.0.0
  class Truncator
    # @return [Hash] the options for +String#encode+
    ENCODING_OPTIONS = { invalid: :replace, undef: :replace }.freeze

    # @return [String] the temporary encoding to be used when fixing invalid
    #   strings with +ENCODING_OPTIONS+
    TEMP_ENCODING = 'utf-16'.freeze

    # @return [Array<Encoding>] encodings that are eligible for fixing invalid
    #   characters
    SUPPORTED_ENCODINGS = [Encoding::UTF_8, Encoding::ASCII].freeze

    # @return [String] what to append when something is a circular reference
    CIRCULAR = '[Circular]'.freeze

    # @return [String] what to append when something is truncated
    TRUNCATED = '[Truncated]'.freeze

    # @return [Array<Class>] The types that can contain references to itself
    CIRCULAR_TYPES = [Array, Hash, Set].freeze

    # @param [Integer] max_size maximum size of hashes, arrays and strings
    def initialize(max_size)
      @max_size = max_size
    end

    # Performs deep truncation of arrays, hashes, sets & strings. Uses a
    # placeholder for recursive objects (`[Circular]`).
    #
    # @param [Object] object The object to truncate
    # @param [Set] seen The cache that helps to detect recursion
    # @return [Object] truncated object
    def truncate(object, seen = Set.new)
      if seen.include?(object.object_id)
        return CIRCULAR if CIRCULAR_TYPES.any? { |t| object.is_a?(t) }

        return object
      end
      truncate_object(object, seen << object.object_id)
    end

    # Reduces maximum allowed size of hashes, arrays, sets & strings by half.
    # @return [Integer] current +max_size+ value
    def reduce_max_size
      @max_size /= 2
    end

    private

    def truncate_object(object, seen)
      case object
      when Hash then truncate_hash(object, seen)
      when Array then truncate_array(object, seen)
      when Set then truncate_set(object, seen)
      when String then truncate_string(object)
      when Numeric, TrueClass, FalseClass, Symbol, NilClass then object
      else
        truncate_string(stringify_object(object))
      end
    end

    def truncate_string(str)
      fixed_str = replace_invalid_characters(str)
      return fixed_str if fixed_str.length <= @max_size

      (fixed_str.slice(0, @max_size) + TRUNCATED).freeze
    end

    def stringify_object(object)
      object.to_json
    rescue *Notice::JSON_EXCEPTIONS
      object.to_s
    end

    def truncate_hash(hash, seen)
      truncated_hash = {}
      hash.each_with_index do |(key, val), idx|
        break if idx + 1 > @max_size

        truncated_hash[key] = truncate(val, seen)
      end

      truncated_hash.freeze
    end

    def truncate_array(array, seen)
      array.slice(0, @max_size).map! { |elem| truncate(elem, seen) }.freeze
    end

    def truncate_set(set, seen)
      truncated_set = Set.new

      set.each do |elem|
        truncated_set << truncate(elem, seen)
        break if truncated_set.size >= @max_size
      end

      truncated_set.freeze
    end

    # Replaces invalid characters in a string with arbitrary encoding.
    #
    # @param [String] str The string to replace characters
    # @return [String] a UTF-8 encoded string
    # @see https://github.com/flori/json/commit/3e158410e81f94dbbc3da6b7b35f4f64983aa4e3
    def replace_invalid_characters(str)
      utf8_string = SUPPORTED_ENCODINGS.include?(str.encoding)
      return str if utf8_string && str.valid_encoding?

      temp_str = str.dup
      temp_str.encode!(TEMP_ENCODING, **ENCODING_OPTIONS) if utf8_string
      temp_str.encode!('utf-8', **ENCODING_OPTIONS)
    end
  end
end

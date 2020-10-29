# frozen_string_literal: true

module ISO8601
  ##
  # Contains all ISO8601-specific errors.
  module Errors
    ##
    # Catch-all exception.
    class StandardError < ::StandardError
    end

    ##
    # Raised when the given pattern doesn't fit as ISO 8601 parser.
    class UnknownPattern < StandardError
      def initialize(pattern)
        super("Unknown pattern #{pattern}")
      end
    end

    ##
    # Raised when the given pattern contains an invalid fraction.
    class InvalidFractions < StandardError
      def initialize
        super("Fractions are only allowed in the last component")
      end
    end

    ##
    # Raised when the given date is valid but out of range.
    class RangeError < StandardError
      def initialize(pattern)
        super("#{pattern} is out of range")
      end
    end

    ##
    # Raised when the type is unexpected
    class TypeError < ::ArgumentError
    end

    ##
    # Raised when the interval is unexpected
    class IntervalError < StandardError
    end

    ##
    # Raise when the base is not suitable.
    class DurationBaseError < StandardError
      def initialize(duration)
        super("Wrong base for #{duration} duration.")
      end
    end
  end
end

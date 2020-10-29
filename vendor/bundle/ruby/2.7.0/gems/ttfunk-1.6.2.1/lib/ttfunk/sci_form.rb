# frozen_string_literal: true

module TTFunk
  class SciForm
    attr_reader :significand, :exponent
    alias eql? ==

    def initialize(significand, exponent = 0)
      @significand = significand
      @exponent = exponent
    end

    def to_f
      significand * 10**exponent
    end

    def ==(other)
      case other
      when Float
        other == to_f
      when self.class
        other.significand == significand &&
          other.exponent == exponent
      else
        false
      end
    end
  end
end

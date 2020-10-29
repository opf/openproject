# frozen_string_literal: true

module TTFunk
  class BitField
    attr_reader :value

    def initialize(value = 0)
      @value = value
    end

    def on(pos)
      @value |= 2**pos
    end

    def on?(pos)
      value & 2**pos > 0
    end

    def off(pos)
      @value &= 2**Math.log2(value).ceil - 2**pos - 1
    end

    def off?(pos)
      !on?(pos)
    end

    def dup
      self.class.new(value)
    end
  end
end

# frozen_string_literal: true

module TTFunk
  class OneBasedArray
    include Enumerable

    def initialize(size = 0)
      @entries = Array.new(size)
    end

    def [](idx)
      if idx == 0
        raise IndexError,
          "index #{idx} was outside the bounds of the array"
      end

      entries[idx - 1]
    end

    def size
      entries.size
    end

    def to_ary
      entries
    end

    def each(&block)
      entries.each(&block)
    end

    private

    attr_reader :entries
  end
end

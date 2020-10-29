# frozen_string_literal: true

module TTFunk
  class Placeholder
    attr_accessor :position
    attr_reader :name, :length

    def initialize(name, length: 1)
      @name = name
      @length = length
    end
  end
end

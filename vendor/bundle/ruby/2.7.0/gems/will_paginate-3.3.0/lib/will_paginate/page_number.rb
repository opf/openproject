require 'forwardable'

module WillPaginate
  # a module that page number exceptions are tagged with
  module InvalidPage; end

  # integer representing a page number
  class PageNumber < Numeric
    # a value larger than this is not supported in SQL queries
    BIGINT = 9223372036854775807

    extend Forwardable

    def initialize(value, name)
      value = Integer(value)
      if 'offset' == name ? (value < 0 or value > BIGINT) : value < 1
        raise RangeError, "invalid #{name}: #{value.inspect}"
      end
      @name = name
      @value = value
    rescue ArgumentError, TypeError, RangeError => error
      error.extend InvalidPage
      raise error
    end

    def to_i
      @value
    end

    def_delegators :@value, :coerce, :==, :<=>, :to_s, :+, :-, :*, :/, :to_json

    def inspect
      "#{@name} #{to_i}"
    end

    def to_offset(per_page)
      PageNumber.new((to_i - 1) * per_page.to_i, 'offset')
    end

    def kind_of?(klass)
      super || to_i.kind_of?(klass)
    end
    alias is_a? kind_of?
  end

  # An idemptotent coercion method
  def self.PageNumber(value, name = 'page')
    case value
    when PageNumber then value
    else PageNumber.new(value, name)
    end
  end
end

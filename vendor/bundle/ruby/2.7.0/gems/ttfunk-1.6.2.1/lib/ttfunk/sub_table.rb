# frozen_string_literal: true

require_relative './reader'

module TTFunk
  class SubTable
    class EOTError < StandardError
    end

    include Reader

    attr_reader :file, :table_offset, :length

    def initialize(file, offset, length = nil)
      @file = file
      @table_offset = offset
      @length = length
      parse_from(@table_offset) { parse! }
    end

    # end of table
    def eot?
      # if length isn't set yet there's no way to know if we're at the end of
      # the table or not
      return false unless length

      io.pos > table_offset + length
    end

    def read(*args)
      if eot?
        raise EOTError, 'attempted to read past the end of the table'
      end

      super
    end
  end
end

# frozen_string_literal: true

module TTFunk
  class Directory
    attr_reader :tables
    attr_reader :scaler_type

    def initialize(io, offset = 0)
      io.seek(offset)

      # https://www.microsoft.com/typography/otspec/otff.htm#offsetTable
      # We're ignoring searchRange, entrySelector, and rangeShift here, but
      # skipping past them to get to the table information.
      @scaler_type, table_count = io.read(12).unpack('Nn')

      @tables = {}
      table_count.times do
        tag, checksum, offset, length = io.read(16).unpack('a4N*')
        @tables[tag] = {
          tag: tag,
          checksum: checksum,
          offset: offset,
          length: length
        }
      end
    end
  end
end

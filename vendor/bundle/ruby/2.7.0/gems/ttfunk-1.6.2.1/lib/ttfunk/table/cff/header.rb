# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class Header < TTFunk::SubTable
        # cff format version numbers
        attr_reader :major
        attr_reader :minor

        # size of the header itself
        attr_reader :header_size

        # size of all offsets from beginning of table
        attr_reader :absolute_offset_size

        def length
          4
        end

        def encode
          [major, minor, header_size, absolute_offset_size].pack('C*')
        end

        private

        def parse!
          @major, @minor, @header_size, @absolute_offset_size = read(4, 'C*')
        end
      end
    end
  end
end

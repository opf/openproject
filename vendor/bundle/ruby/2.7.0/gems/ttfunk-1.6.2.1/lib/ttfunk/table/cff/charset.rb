# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class Charset < TTFunk::SubTable
        include Enumerable

        FIRST_GLYPH_STRING = '.notdef'
        ARRAY_FORMAT = 0
        RANGE_FORMAT_8 = 1
        RANGE_FORMAT_16 = 2

        ISO_ADOBE_CHARSET_ID = 0
        EXPERT_CHARSET_ID = 1
        EXPERT_SUBSET_CHARSET_ID = 2

        DEFAULT_CHARSET_ID = ISO_ADOBE_CHARSET_ID

        class << self
          def standard_strings
            Charsets::STANDARD_STRINGS
          end

          def strings_for_charset_id(charset_id)
            case charset_id
            when ISO_ADOBE_CHARSET_ID
              Charsets::ISO_ADOBE
            when EXPERT_CHARSET_ID
              Charsets::EXPERT
            when EXPERT_SUBSET_CHARSET_ID
              Charsets::EXPERT_SUBSET
            end
          end
        end

        attr_reader :entries, :length
        attr_reader :top_dict, :format, :count, :offset_or_id

        def initialize(top_dict, file, offset_or_id = nil, length = nil)
          @top_dict = top_dict
          @offset_or_id = offset_or_id || DEFAULT_CHARSET_ID

          if offset
            super(file, offset, length)
          else
            @count = self.class.strings_for_charset_id(offset_or_id).size
          end
        end

        def each
          return to_enum(__method__) unless block_given?

          # +1 adjusts for the implicit .notdef glyph
          (count + 1).times { |i| yield self[i] }
        end

        def [](glyph_id)
          return FIRST_GLYPH_STRING if glyph_id == 0

          find_string(sid_for(glyph_id))
        end

        def offset
          # Numbers from 0..2 mean charset IDs instead of offsets. IDs are
          # basically pre-defined sets of characters.
          #
          # In the case of an offset, add the CFF table's offset since the
          # charset offset is relative to the start of the CFF table. Otherwise
          # return nil (no offset).
          if offset_or_id > 2
            offset_or_id + top_dict.cff_offset
          end
        end

        # mapping is new -> old glyph ids
        def encode(mapping)
          # no offset means no charset was specified (i.e. we're supposed to
          # use a predefined charset) so there's nothing to encode
          return '' unless offset

          sids = mapping.keys.sort.map { |new_gid| sid_for(mapping[new_gid]) }
          ranges = TTFunk::BinUtils.rangify(sids)
          range_max = ranges.map(&:last).max

          range_bytes = if range_max > 0
                          (Math.log2(range_max) / 8).floor + 1
                        else
                          # for cases when there are no sequences at all
                          Float::INFINITY
                        end

          # calculate whether storing the charset as a series of ranges is
          # more efficient (i.e. takes up less space) vs storing it as an
          # array of SID values
          total_range_size = (2 * ranges.size) + (range_bytes * ranges.size)
          total_array_size = sids.size * element_width(:array_format)

          if total_array_size <= total_range_size
            ([format_int(:array_format)] + sids).pack('Cn*')
          else
            fmt = range_bytes == 1 ? :range_format_8 : :range_format_16
            element_fmt = element_format(fmt)
            result = [format_int(fmt)].pack('C')
            ranges.each { |range| result << range.pack(element_fmt) }
            result
          end
        end

        private

        def sid_for(glyph_id)
          return 0 if glyph_id == 0

          # rather than validating the glyph as part of one of the predefined
          # charsets, just pass it through
          return glyph_id unless offset

          case format_sym
          when :array_format
            entries[glyph_id]

          when :range_format_8, :range_format_16
            entries.inject(glyph_id) do |remaining, range|
              if range.size >= remaining
                break (range.first + remaining) - 1
              end

              remaining - range.size
            end
          end
        end

        def find_string(sid)
          if offset
            return self.class.standard_strings[sid] if sid <= 390

            idx = sid - 390

            if idx < file.cff.string_index.count
              file.cff.string_index[idx]
            end
          else
            self.class.strings_for_charset_id(offset_or_id)[sid]
          end
        end

        def parse!
          return unless offset

          @format = read(1, 'C').first

          case format_sym
          when :array_format
            @count = top_dict.charstrings_index.count - 1
            @length = count * element_width
            @entries = OneBasedArray.new(read(length, 'n*'))

          when :range_format_8, :range_format_16
            # The number of ranges is not explicitly specified in the font.
            # Instead, software utilizing this data simply processes ranges
            # until all glyphs in the font are covered.
            @count = 0
            @entries = []
            @length = 0

            until count >= top_dict.charstrings_index.count - 1
              @length += 1 + element_width
              sid, num_left = read(element_width, element_format)
              entries << (sid..(sid + num_left))
              @count += num_left + 1
            end
          end
        end

        def element_width(fmt = format_sym)
          case fmt
          when :array_format then 2 # SID
          when :range_format_8 then 3 # SID + Card8
          when :range_format_16 then 4 # SID + Card16
          end
        end

        def element_format(fmt = format_sym)
          case fmt
          when :array_format then 'n'
          when :range_format_8 then 'nC'
          when :range_format_16 then 'nn'
          end
        end

        def format_sym
          case @format
          when ARRAY_FORMAT then :array_format
          when RANGE_FORMAT_8 then :range_format_8
          when RANGE_FORMAT_16 then :range_format_16
          else
            raise "unsupported charset format '#{fmt}'"
          end
        end

        def format_int(sym = format_sym)
          case sym
          when :array_format then ARRAY_FORMAT
          when :range_format_8 then RANGE_FORMAT_8
          when :range_format_16 then RANGE_FORMAT_16
          end
        end
      end
    end
  end
end

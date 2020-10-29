# frozen_string_literal: true

require_relative '../table'
require 'set'

module TTFunk
  class Table
    class OS2 < Table
      attr_reader :version

      attr_reader :ave_char_width
      attr_reader :weight_class
      attr_reader :width_class
      attr_reader :type
      attr_reader :y_subscript_x_size
      attr_reader :y_subscript_y_size
      attr_reader :y_subscript_x_offset
      attr_reader :y_subscript_y_offset
      attr_reader :y_superscript_x_size
      attr_reader :y_superscript_y_size
      attr_reader :y_superscript_x_offset
      attr_reader :y_superscript_y_offset
      attr_reader :y_strikeout_size
      attr_reader :y_strikeout_position
      attr_reader :family_class
      attr_reader :panose
      attr_reader :char_range
      attr_reader :vendor_id
      attr_reader :selection
      attr_reader :first_char_index
      attr_reader :last_char_index

      attr_reader :ascent
      attr_reader :descent
      attr_reader :line_gap
      attr_reader :win_ascent
      attr_reader :win_descent
      attr_reader :code_page_range

      attr_reader :x_height
      attr_reader :cap_height
      attr_reader :default_char
      attr_reader :break_char
      attr_reader :max_context

      CODE_PAGE_BITS = {
        1252 => 0,  1250 => 1,  1251 => 2,  1253 => 3,  1254 => 4,
        1255 => 5,  1256 => 6,  1257 => 7,  1258 => 8,  874  => 16,
        932 => 17, 936 => 18, 949 => 19, 950 => 20, 1361 => 21,
        10_000 => 29, 869 => 48, 866 => 49, 865 => 50, 864 => 51,
        863 => 52, 862  => 53, 861  => 54, 860  => 55, 857  => 56,
        855 => 57, 852  => 58, 775  => 59, 737  => 60, 708  => 61,
        850 => 62, 437  => 63
      }.freeze

      UNICODE_BLOCKS = {
        (0x0000..0x007F) => 0, (0x0080..0x00FF) => 1,
        (0x0100..0x017F) => 2, (0x0180..0x024F) => 3,
        (0x0250..0x02AF) => 4, (0x1D00..0x1D7F) => 4,
        (0x1D80..0x1DBF) => 4, (0x02B0..0x02FF) => 5,
        (0xA700..0xA71F) => 5, (0x0300..0x036F) => 6,
        (0x1DC0..0x1DFF) => 6, (0x0370..0x03FF) => 7,
        (0x2C80..0x2CFF) => 8, (0x0400..0x04FF) => 9,
        (0x0500..0x052F) => 9, (0x2DE0..0x2DFF) => 9,
        (0xA640..0xA69F) => 9, (0x0530..0x058F) => 10,
        (0x0590..0x05FF) => 11, (0xA500..0xA63F) => 12,
        (0x0600..0x06FF) => 13, (0x0750..0x077F) => 13,
        (0x07C0..0x07FF) => 14, (0x0900..0x097F) => 15,
        (0x0980..0x09FF) => 16, (0x0A00..0x0A7F) => 17,
        (0x0A80..0x0AFF) => 18, (0x0B00..0x0B7F) => 19,
        (0x0B80..0x0BFF) => 20, (0x0C00..0x0C7F) => 21,
        (0x0C80..0x0CFF) => 22, (0x0D00..0x0D7F) => 23,
        (0x0E00..0x0E7F) => 24, (0x0E80..0x0EFF) => 25,
        (0x10A0..0x10FF) => 26, (0x2D00..0x2D2F) => 26,
        (0x1B00..0x1B7F) => 27, (0x1100..0x11FF) => 28,
        (0x1E00..0x1EFF) => 29, (0x2C60..0x2C7F) => 29,
        (0xA720..0xA7FF) => 29, (0x1F00..0x1FFF) => 30,
        (0x2000..0x206F) => 31, (0x2E00..0x2E7F) => 31,
        (0x2070..0x209F) => 32, (0x20A0..0x20CF) => 33,
        (0x20D0..0x20FF) => 34, (0x2100..0x214F) => 35,
        (0x2150..0x218F) => 36, (0x2190..0x21FF) => 37,
        (0x27F0..0x27FF) => 37, (0x2900..0x297F) => 37,
        (0x2B00..0x2BFF) => 37, (0x2200..0x22FF) => 38,
        (0x2A00..0x2AFF) => 38, (0x27C0..0x27EF) => 38,
        (0x2980..0x29FF) => 38, (0x2300..0x23FF) => 39,
        (0x2400..0x243F) => 40, (0x2440..0x245F) => 41,
        (0x2460..0x24FF) => 42, (0x2500..0x257F) => 43,
        (0x2580..0x259F) => 44, (0x25A0..0x25FF) => 45,
        (0x2600..0x26FF) => 46, (0x2700..0x27BF) => 47,
        (0x3000..0x303F) => 48, (0x3040..0x309F) => 49,
        (0x30A0..0x30FF) => 50, (0x31F0..0x31FF) => 50,
        (0x3100..0x312F) => 51, (0x31A0..0x31BF) => 51,
        (0x3130..0x318F) => 52, (0xA840..0xA87F) => 53,
        (0x3200..0x32FF) => 54, (0x3300..0x33FF) => 55,
        (0xAC00..0xD7AF) => 56, (0xD800..0xDFFF) => 57,
        (0x10900..0x1091F) => 58, (0x4E00..0x9FFF) => 59,
        (0x2E80..0x2EFF) => 59, (0x2F00..0x2FDF) => 59,
        (0x2FF0..0x2FFF) => 59, (0x3400..0x4DBF) => 59,
        (0x20000..0x2A6DF) => 59, (0x3190..0x319F) => 59,
        (0xE000..0xF8FF) => 60, (0x31C0..0x31EF) => 61,
        (0xF900..0xFAFF) => 61, (0x2F800..0x2FA1F) => 61,
        (0xFB00..0xFB4F) => 62, (0xFB50..0xFDFF) => 63,
        (0xFE20..0xFE2F) => 64, (0xFE10..0xFE1F) => 65,
        (0xFE30..0xFE4F) => 65, (0xFE50..0xFE6F) => 66,
        (0xFE70..0xFEFF) => 67, (0xFF00..0xFFEF) => 68,
        (0xFFF0..0xFFFF) => 69, (0x0F00..0x0FFF) => 70,
        (0x0700..0x074F) => 71, (0x0780..0x07BF) => 72,
        (0x0D80..0x0DFF) => 73, (0x1000..0x109F) => 74,
        (0x1200..0x137F) => 75, (0x1380..0x139F) => 75,
        (0x2D80..0x2DDF) => 75, (0x13A0..0x13FF) => 76,
        (0x1400..0x167F) => 77, (0x1680..0x169F) => 78,
        (0x16A0..0x16FF) => 79, (0x1780..0x17FF) => 80,
        (0x19E0..0x19FF) => 80, (0x1800..0x18AF) => 81,
        (0x2800..0x28FF) => 82, (0xA000..0xA48F) => 83,
        (0xA490..0xA4CF) => 83, (0x1700..0x171F) => 84,
        (0x1720..0x173F) => 84, (0x1740..0x175F) => 84,
        (0x1760..0x177F) => 84, (0x10300..0x1032F) => 85,
        (0x10330..0x1034F) => 86, (0x10400..0x1044F) => 87,
        (0x1D000..0x1D0FF) => 88, (0x1D100..0x1D1FF) => 88,
        (0x1D200..0x1D24F) => 88, (0x1D400..0x1D7FF) => 89,
        (0xF0000..0xFFFFD) => 90, (0x100000..0x10FFFD) => 90,
        (0xFE00..0xFE0F) => 91, (0xE0100..0xE01EF) => 91,
        (0xE0000..0xE007F) => 92, (0x1900..0x194F) => 93,
        (0x1950..0x197F) => 94, (0x1980..0x19DF) => 95,
        (0x1A00..0x1A1F) => 96, (0x2C00..0x2C5F) => 97,
        (0x2D30..0x2D7F) => 98, (0x4DC0..0x4DFF) => 99,
        (0xA800..0xA82F) => 100, (0x10000..0x1007F) => 101,
        (0x10080..0x100FF) => 101, (0x10100..0x1013F) => 101,
        (0x10140..0x1018F) => 102, (0x10380..0x1039F) => 103,
        (0x103A0..0x103DF) => 104, (0x10450..0x1047F) => 105,
        (0x10480..0x104AF) => 106, (0x10800..0x1083F) => 107,
        (0x10A00..0x10A5F) => 108, (0x1D300..0x1D35F) => 109,
        (0x12000..0x123FF) => 110, (0x12400..0x1247F) => 110,
        (0x1D360..0x1D37F) => 111, (0x1B80..0x1BBF) => 112,
        (0x1C00..0x1C4F) => 113, (0x1C50..0x1C7F) => 114,
        (0xA880..0xA8DF) => 115, (0xA900..0xA92F) => 116,
        (0xA930..0xA95F) => 117, (0xAA00..0xAA5F) => 118,
        (0x10190..0x101CF) => 119, (0x101D0..0x101FF) => 120,
        (0x102A0..0x102DF) => 121, (0x10280..0x1029F) => 121,
        (0x10920..0x1093F) => 121, (0x1F030..0x1F09F) => 122,
        (0x1F000..0x1F02F) => 122
      }.freeze

      UNICODE_MAX = 0xFFFF
      UNICODE_RANGES = UNICODE_BLOCKS.keys.freeze
      LOWERCASE_START = 'a'.ord
      LOWERCASE_END = 'z'.ord
      LOWERCASE_COUNT = (LOWERCASE_END - LOWERCASE_START) + 1
      CODEPOINT_SPACE = 32
      SPACE_GLYPH_MISSING_ERROR = "Space glyph (0x#{CODEPOINT_SPACE.to_s(16)})"\
        ' must be included in the font'

      # Used to calculate the xAvgCharWidth field.
      # From https://docs.microsoft.com/en-us/typography/opentype/spec/os2:
      #
      # "When first defined, the specification was biased toward Basic Latin
      # characters, and it was thought that the xAvgCharWidth value could be
      # used to estimate the average length of lines of text. A formula for
      # calculating xAvgCharWidth was provided using frequency-of-use
      # weighting factors for lowercase letters a - z."
      #
      # The array below contains 26 weight values which correspond to the
      # 26 letters in the Latin alphabet. Each weight is the relative
      # frequency of that letter in the English language.
      WEIGHT_SPACE = 166
      WEIGHT_LOWERCASE = [
        64, 14, 27, 35, 100, 20, 14, 42, 63, 3, 6, 35, 20,
        56, 56, 17, 4, 49, 56, 71, 31, 10, 18, 3, 18, 2
      ].freeze

      def tag
        'OS/2'
      end

      class << self
        def encode(os2, subset)
          ''.b.tap do |result|
            result << [
              os2.version, avg_char_width_for(os2, subset), os2.weight_class,
              os2.width_class, os2.type, os2.y_subscript_x_size,
              os2.y_subscript_y_size, os2.y_subscript_x_offset,
              os2.y_subscript_y_offset, os2.y_superscript_x_size,
              os2.y_superscript_y_size, os2.y_superscript_x_offset,
              os2.y_superscript_y_offset, os2.y_strikeout_size,
              os2.y_strikeout_position, os2.family_class
            ].pack('n*')

            result << os2.panose

            new_char_range = unicode_blocks_for(os2, os2.char_range, subset)
            result << BinUtils
                      .slice_int(
                        new_char_range.value,
                        bit_width: 32,
                        slice_count: 4
                      )
                      .pack('N*')

            result << os2.vendor_id

            new_cmap_table = subset.new_cmap_table[:charmap]
            code_points = new_cmap_table
                          .keys
                          .select { |k| new_cmap_table[k][:new] > 0 }
                          .sort

            # "This value depends on which character sets the font supports.
            # This field cannot represent supplementary character values
            # (codepoints greater than 0xFFFF). Fonts that support
            # supplementary characters should set the value in this field
            # to 0xFFFF."
            first_char_index = [code_points.first || 0, UNICODE_MAX].min
            last_char_index = [code_points.last || 0, UNICODE_MAX].min

            result << [
              os2.selection, first_char_index, last_char_index
            ].pack('n*')

            if os2.version > 0
              result << [
                os2.ascent, os2.descent, os2.line_gap,
                os2.win_ascent, os2.win_descent
              ].pack('n*')

              result << BinUtils
                        .slice_int(
                          code_pages_for(subset).value,
                          bit_width: 32,
                          slice_count: 2
                        )
                        .pack('N*')

              if os2.version > 1
                result << [
                  os2.x_height, os2.cap_height, os2.default_char,
                  os2.break_char, os2.max_context
                ].pack('n*')
              end
            end
          end
        end

        private

        def code_pages_for(subset)
          field = BitField.new(0)
          return field if subset.unicode?

          field.on(CODE_PAGE_BITS[subset.code_page])
          field
        end

        def unicode_blocks_for(os2, original_field, subset)
          field = BitField.new(0)
          return field unless subset.unicode?

          subset_code_points = Set.new(subset.new_cmap_table[:charmap].keys)
          original_code_point_groups = group_original_code_points_by_bit(os2)

          original_code_point_groups.each do |bit, code_points|
            next if original_field.off?(bit)

            if code_points.any? { |cp| subset_code_points.include?(cp) }
              field.on(bit)
            end
          end

          field
        end

        def group_original_code_points_by_bit(os2)
          Hash.new { |h, k| h[k] = [] }.tap do |result|
            os2.file.cmap.unicode.first.code_map.each_key do |code_point|
              # find corresponding bit
              range = UNICODE_RANGES.find { |r| r.cover?(code_point) }

              if (bit = UNICODE_BLOCKS[range])
                result[bit] << code_point
              end
            end
          end
        end

        def avg_char_width_for(os2, subset)
          if subset.microsoft_symbol?
            avg_ms_symbol_char_width_for(os2, subset)
          else
            avg_weighted_char_width_for(os2, subset)
          end
        end

        def avg_ms_symbol_char_width_for(os2, subset)
          total_width = 0
          num_glyphs = 0

          # use new -> old glyph mapping in order to include compound glyphs
          # in the calculation
          subset.new_to_old_glyph.each do |_, old_gid|
            if (metric = os2.file.horizontal_metrics.for(old_gid))
              total_width += metric.advance_width
              num_glyphs += 1 if metric.advance_width > 0
            end
          end

          return 0 if num_glyphs == 0

          total_width / num_glyphs # this should be a whole number
        end

        def avg_weighted_char_width_for(os2, subset)
          # make sure the subset includes the space char
          unless subset.to_unicode_map[CODEPOINT_SPACE]
            raise SPACE_GLYPH_MISSING_ERROR
          end

          space_gid = os2.file.cmap.unicode.first[CODEPOINT_SPACE]
          space_hm = os2.file.horizontal_metrics.for(space_gid)
          return 0 unless space_hm

          total_weight = space_hm.advance_width * WEIGHT_SPACE
          num_lowercase = 0

          # calculate the weighted sum of all the lowercase widths in
          # the subset
          LOWERCASE_START.upto(LOWERCASE_END) do |lowercase_cp|
            # make sure the subset includes the character
            next unless subset.to_unicode_map[lowercase_cp]

            lowercase_gid = os2.file.cmap.unicode.first[lowercase_cp]
            lowercase_hm = os2.file.horizontal_metrics.for(lowercase_gid)

            num_lowercase += 1
            total_weight += lowercase_hm.advance_width *
              WEIGHT_LOWERCASE[lowercase_cp - 'a'.ord]
          end

          # return if all lowercase characters are present in the subset
          return total_weight / 1000 if num_lowercase == LOWERCASE_COUNT

          # If not all lowercase characters are present in the subset, take
          # the average width of all the subsetted characters. This differs
          # from avg_ms_char_width_for in that it includes zero-width glyphs
          # in the calculation.
          total_width = 0
          num_glyphs = subset.new_to_old_glyph.size

          # use new -> old glyph mapping in order to include compound glyphs
          # in the calculation
          subset.new_to_old_glyph.each do |_, old_gid|
            if (metric = os2.file.horizontal_metrics.for(old_gid))
              total_width += metric.advance_width
            end
          end

          return 0 if num_glyphs == 0

          total_width / num_glyphs # this should be a whole number
        end
      end

      private

      def parse!
        @version = read(2, 'n').first

        @ave_char_width = read_signed(1).first
        @weight_class, @width_class = read(4, 'nn')
        @type, @y_subscript_x_size, @y_subscript_y_size, @y_subscript_x_offset,
          @y_subscript_y_offset, @y_superscript_x_size, @y_superscript_y_size,
          @y_superscript_x_offset, @y_superscript_y_offset, @y_strikeout_size,
          @y_strikeout_position, @family_class = read_signed(12)
        @panose = io.read(10)

        @char_range = BitField.new(
          BinUtils.stitch_int(read(16, 'N*'), bit_width: 32)
        )

        @vendor_id = io.read(4)
        @selection, @first_char_index, @last_char_index = read(6, 'n*')

        if @version > 0
          @ascent, @descent, @line_gap = read_signed(3)
          @win_ascent, @win_descent = read(4, 'nn')
          @code_page_range = BitField.new(
            BinUtils.stitch_int(read(8, 'N*'), bit_width: 32)
          )

          if @version > 1
            @x_height, @cap_height = read_signed(2)
            @default_char, @break_char, @max_context = read(6, 'nnn')

            # Set this to zero until GSUB/GPOS support has been implemented.
            # This value is calculated via those tables, and should be set to
            # zero if the data is not available.
            @max_context = 0
          end
        end
      end
    end
  end
end

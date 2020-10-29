# frozen_string_literal: true

module TTFunk
  class Table
    class Cff < TTFunk::Table
      class Charstring
        CODE_MAP = {
          1 => :hstem,
          3 => :vstem,
          4 => :vmoveto,
          5 => :rlineto,
          6 => :hlineto,
          7 => :vlineto,
          8 => :rrcurveto,
          10 => :callsubr,
          12 => :flex_select,
          14 => :endchar,
          18 => :hstemhm,
          19 => :hintmask,
          20 => :cntrmask,
          21 => :rmoveto,
          22 => :hmoveto,
          23 => :vstemhm,
          24 => :rcurveline,
          25 => :rlinecurve,
          26 => :vvcurveto,
          27 => :hhcurveto,
          28 => :shortint,
          29 => :callgsubr,
          30 => :vhcurveto,
          31 => :hvcurveto
        }.freeze

        FLEX_CODE_MAP = {
          35 => :flex,
          34 => :hflex,
          36 => :hflex1,
          37 => :flex1
        }.freeze

        attr_reader :glyph_id, :raw

        def initialize(glyph_id, top_dict, font_dict, raw)
          @glyph_id = glyph_id
          @top_dict = top_dict
          @font_dict = font_dict
          @raw = raw

          default_width_x = (@font_dict || @top_dict)
                            .private_dict.default_width_x

          @nominal_width_x = (@font_dict || @top_dict)
                             .private_dict.nominal_width_x

          @subrs = (@font_dict || @top_dict).private_dict.subr_index
          @gsubrs = @top_dict.cff.global_subr_index
          @subrs_bias = @subrs.bias if @subrs
          @gsubrs_bias = @gsubrs.bias if @gsubrs

          @stack = []
          @data = raw.bytes
          @index = 0
          @n_stems = 0
          @have_width = false
          @open = false
          @width = default_width_x
          @x = 0
          @y = 0
        end

        def path
          @path || begin
            @path = Path.new
            parse!
            @path
          end
        end

        def glyph
          @glyph ||= begin
            horizontal_metrics = @top_dict.file.horizontal_metrics.for(glyph_id)
            Glyf::PathBased.new(path, horizontal_metrics)
          end
        end

        def render(x: 0, y: 0, font_size: 72)
          path.render(
            x: x,
            y: y,
            font_size: font_size,
            units_per_em: @top_dict.file.header.units_per_em
          )
        end

        def encode
          raw
        end

        private

        def parse!
          until @index >= @data.size
            code = @data[@index]
            @index += 1

            # return from callgsubr - do nothing since we inline subrs
            next if code == 11

            if code >= 32 && code <= 246
              @stack << code - 139
            elsif (m = CODE_MAP[code])
              send(m)
            elsif code >= 247 && code <= 250
              b0 = code
              b1 = @data[@index]
              @index += 1
              @stack << (b0 - 247) * 256 + b1 + 108
            elsif code >= 251 && code <= 254
              b0 = code
              b1 = @data[@index]
              @index += 1
              @stack << -(b0 - 251) * 256 - b1 - 108
            else
              b1, b2, b3, b4 = read_bytes(4)
              @stack << ((b1 << 24) | (b2 << 16) | (b3 << 8) | b4) / 65_536
            end
          end
        end

        def read_bytes(length)
          bytes = @data[@index, length]
          @index += length
          bytes
        end

        def hstem
          stem
        end

        def vstem
          stem
        end

        # rubocop:disable Style/EvenOdd
        def stem
          # The number of stem operators on the stack is always even.
          # If the value is uneven, that means a width is specified.
          has_width_arg = @stack.size % 2 == 1

          if has_width_arg && !@have_width
            @width = @stack.shift + @nominal_width_x
          end

          @n_stems += @stack.length >> 1
          @stack.clear
          @have_width = true
        end
        # rubocop:enable Style/EvenOdd

        def vmoveto
          if @stack.size > 1 && !@have_width
            @width = @stack.shift + @nominal_width_x
            @have_width = true
          end

          @y += @stack.pop
          add_contour(@x, @y)
        end

        def add_contour(x, y)
          if @open
            @path.close_path
          end

          @path.move_to(x, y)
          @open = true
        end

        def rlineto
          until @stack.empty?
            @x += @stack.shift
            @y += @stack.shift
            @path.line_to(@x, @y)
          end
        end

        def hlineto
          until @stack.empty?
            @x += @stack.shift
            @path.line_to(@x, @y)

            break if @stack.empty?

            @y += @stack.shift
            @path.line_to(@x, @y)
          end
        end

        def vlineto
          until @stack.empty?
            @y += @stack.shift
            @path.line_to(@x, @y)

            break if @stack.empty?

            @x += @stack.shift
            @path.line_to(@x, @y)
          end
        end

        def rrcurveto
          until @stack.empty?
            c1x = @x + @stack.shift
            c1y = @y + @stack.shift
            c2x = c1x + @stack.shift
            c2y = c1y + @stack.shift
            @x = c2x + @stack.shift
            @y = c2y + @stack.shift
            @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)
          end
        end

        def callsubr
          code_index = @stack.pop + @subrs_bias
          subr_code = @subrs[code_index].bytes
          @data[@index, 0] = subr_code
        end

        def flex_select
          flex_code = @data[@index]
          @index += 1
          send(FLEX_CODE_MAP[flex_code])
        end

        def flex
          c1x = @x  + @stack.shift    # dx1
          c1y = @y  + @stack.shift    # dy1
          c2x = c1x + @stack.shift    # dx2
          c2y = c1y + @stack.shift    # dy2
          jpx = c2x + @stack.shift    # dx3
          jpy = c2y + @stack.shift    # dy3
          c3x = jpx + @stack.shift    # dx4
          c3y = jpy + @stack.shift    # dy4
          c4x = c3x + @stack.shift    # dx5
          c4y = c3y + @stack.shift    # dy5
          @x  = c4x + @stack.shift    # dx6
          @y  = c4y + @stack.shift    # dy6
          @stack.shift                # flex depth

          @path.curve_to(c1x, c1y, c2x, c2y, jpx, jpy)
          @path.curve_to(c3x, c3y, c4x, c4y, @x, @y)
        end

        def hflex
          c1x = @x + @stack.shift     # dx1
          c1y = @y                    # dy1
          c2x = c1x + @stack.shift    # dx2
          c2y = c1y + @stack.shift    # dy2
          jpx = c2x + @stack.shift    # dx3
          jpy = c2y                   # dy3
          c3x = jpx + stack.shift     # dx4
          c3y = c2y                   # dy4
          c4x = c3x + stack.shift     # dx5
          c4y = @y                    # dy5
          @x  = c4x + stack.shift     # dx6

          @path.curve_to(c1x, c1y, c2x, c2y, jpx, jpy)
          @path.curve_to(c3x, c3y, c4x, c4y, @x, @y)
        end

        def hflex1
          c1x = @x  + @stack.shift    # dx1
          c1y = @y  + @stack.shift    # dy1
          c2x = c1x + @stack.shift    # dx2
          c2y = c1y + @stack.shift    # dy2
          jpx = c2x + @stack.shift    # dx3
          jpy = c2y                   # dy3
          c3x = jpx + @stack.shift    # dx4
          c3y = c2y                   # dy4
          c4x = c3x + @stack.shift    # dx5
          c4y = c3y + @stack.shift    # dy5
          @x  = c4x + @stack.shift    # dx6

          @path.curve_to(c1x, c1y, c2x, c2y, jpx, jpy)
          @path.curve_to(c3x, c3y, c4x, c4y, @x, @y)
        end

        def flex1
          c1x = @x  + @stack.shift    # dx1
          c1y = @y  + @stack.shift    # dy1
          c2x = c1x + @stack.shift    # dx2
          c2y = c1y + @stack.shift    # dy2
          jpx = c2x + @stack.shift    # dx3
          jpy = c2y + @stack.shift    # dy3
          c3x = jpx + @stack.shift    # dx4
          c3y = jpy + @stack.shift    # dy4
          c4x = c3x + @stack.shift    # dx5
          c4y = c3y + @stack.shift    # dy5

          if (c4x - @x).abs > (c4y - @y).abs
            @x = c4x + @stack.shift
          else
            @y = c4y + @stack.shift
          end

          @path.curve_to(c1x, c1y, c2x, c2y, jpx, jpy)
          @path.curve_to(c3x, c3y, c4x, c4y, @x, @y)
        end

        def endchar
          if !@stack.empty? && !@have_width
            @width = @stack.shift + @nominal_width_x
            @have_width = true
          end

          if @open
            @path.close_path
            @open = false
          end
        end

        def hstemhm
          stem
        end

        def hintmask
          cntrmask
        end

        def cntrmask
          stem

          # skip past hinting data, no need to worry about it since we're not
          # very concerned about rendering glyphs
          read_bytes((@n_stems + 7) >> 3)
        end

        def rmoveto
          if @stack.size > 2 && !@have_width
            @width = @stack.shift + @nominal_width_x
            @have_width = true
          end

          @y += @stack.pop
          @x += @stack.pop
          add_contour(@x, @y)
        end

        def hmoveto
          if @stack.size > 1 && !@have_width
            @width = @stack.shift + @nominal_width_x
            @have_width = true
          end

          @x += @stack.pop
          add_contour(@x, @y)
        end

        def vstemhm
          stem
        end

        def rcurveline
          while @stack.size > 2
            c1x = @x + @stack.shift
            c1y = @y + @stack.shift
            c2x = c1x + @stack.shift
            c2y = c1y + @stack.shift
            @x = c2x + @stack.shift
            @y = c2y + @stack.shift
            @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)
          end

          @x += @stack.shift
          @y += @stack.shift
          @path.line_to(@x, @y)
        end

        def rlinecurve
          while @stack.size > 6
            @x += @stack.shift
            @y += @stack.shift
            @path.line_to(@x, @y)
          end

          c1x = @x + @stack.shift
          c1y = @y + @stack.shift
          c2x = c1x + @stack.shift
          c2y = c1y + @stack.shift
          @x = c2x + @stack.shift
          @y = c2y + @stack.shift

          @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)
        end

        # rubocop:disable Style/EvenOdd
        def vvcurveto
          if @stack.size % 2 == 1
            @x += @stack.shift
          end

          until @stack.empty?
            c1x = @x
            c1y = @y + @stack.shift
            c2x = c1x + @stack.shift
            c2y = c1y + @stack.shift
            @x = c2x
            @y = c2y + @stack.shift
            @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)
          end
        end

        def hhcurveto
          if @stack.size % 2 == 1
            @y += @stack.shift
          end

          until @stack.empty?
            c1x = @x + @stack.shift
            c1y = @y
            c2x = c1x + @stack.shift
            c2y = c1y + @stack.shift
            @x = c2x + @stack.shift
            @y = c2y
            @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)
          end
        end
        # rubocop:enable Style/EvenOdd

        def shortint
          b1, b2 = read_bytes(2)
          @stack << (((b1 << 24) | (b2 << 16)) >> 16)
        end

        def callgsubr
          code_index = @stack.pop + @gsubrs_bias
          subr_code = @gsubrs[code_index].bytes
          @data[@index, 0] = subr_code
        end

        def vhcurveto
          until @stack.empty?
            c1x = @x
            c1y = @y + @stack.shift
            c2x = c1x + @stack.shift
            c2y = c1y + @stack.shift
            @x = c2x + @stack.shift
            @y = c2y + (@stack.size == 1 ? @stack.shift : 0)
            @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)

            break if @stack.empty?

            c1x = @x + @stack.shift
            c1y = @y
            c2x = c1x + @stack.shift
            c2y = c1y + @stack.shift
            @y = c2y + @stack.shift
            @x = c2x + (@stack.size == 1 ? @stack.shift : 0)
            @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)
          end
        end

        def hvcurveto
          until @stack.empty?
            c1x = @x + @stack.shift
            c1y = @y
            c2x = c1x + @stack.shift
            c2y = c1y + @stack.shift
            @y = c2y + @stack.shift
            @x = c2x + (@stack.size == 1 ? @stack.shift : 0)
            @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)

            break if @stack.empty?

            c1x = @x
            c1y = @y + @stack.shift
            c2x = c1x + @stack.shift
            c2y = c1y + @stack.shift
            @x = c2x + @stack.shift
            @y = c2y + (@stack.size == 1 ? @stack.shift : 0)
            @path.curve_to(c1x, c1y, c2x, c2y, @x, @y)
          end
        end
      end
    end
  end
end

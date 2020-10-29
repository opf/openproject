# frozen_string_literal: true

# prawn/font/ttf.rb : Implements AFM font support for Prawn
#
# Copyright May 2008, Gregory Brown / James Healy / Jamis Buck
# All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require 'ttfunk'
require 'ttfunk/subset_collection'

module Prawn
  module Fonts
    # @private
    class TTF < Font
      attr_reader :ttf, :subsets

      def unicode?
        true
      end

      def initialize(document, name, options = {})
        super

        @ttf = read_ttf_file
        @subsets = TTFunk::SubsetCollection.new(@ttf)
        @italic_angle = nil

        @attributes = {}
        @bounding_boxes = {}
        @char_widths = {}
        @has_kerning_data = @ttf.kerning.exists? && @ttf.kerning.tables.any?

        @ascender = Integer(@ttf.ascent * scale_factor)
        @descender = Integer(@ttf.descent * scale_factor)
        @line_gap = Integer(@ttf.line_gap * scale_factor)
      end

      # NOTE: +string+ must be UTF8-encoded.
      def compute_width_of(string, options = {}) #:nodoc:
        scale = (options[:size] || size) / 1000.0
        if options[:kerning]
          kern(string).inject(0) do |s, r|
            if r.is_a?(Numeric)
              s - r
            else
              r.inject(s) { |a, e| a + character_width_by_code(e) }
            end
          end * scale
        else
          string.codepoints.inject(0) do |s, r|
            s + character_width_by_code(r)
          end * scale
        end
      end

      # The font bbox, as an array of integers
      #
      def bbox
        @bbox ||= @ttf.bbox.map { |i| Integer(i * scale_factor) }
      end

      # Returns true if the font has kerning data, false otherwise
      #
      # rubocop: disable Naming/PredicateName
      def has_kerning_data?
        @has_kerning_data
      end
      # rubocop: enable Naming/PredicateName

      # Perform any changes to the string that need to happen
      # before it is rendered to the canvas. Returns an array of
      # subset "chunks", where the even-numbered indices are the
      # font subset number, and the following entry element is
      # either a string or an array (for kerned text).
      #
      # The +text+ parameter must be UTF8-encoded.
      #
      def encode_text(text, options = {})
        text = text.chomp

        if options[:kerning]
          last_subset = nil
          kern(text).inject([]) do |result, element|
            if element.is_a?(Numeric)
              unless result.last[1].is_a?(Array)
                result.last[1] = [result.last[1]]
              end
              result.last[1] << element
              result
            else
              encoded = @subsets.encode(element)

              if encoded.first[0] == last_subset
                result.last[1] << encoded.first[1]
                encoded.shift
              end

              if encoded.any?
                last_subset = encoded.last[0]
                result + encoded
              else
                result
              end
            end
          end
        else
          @subsets.encode(text.unpack('U*'))
        end
      end

      def basename
        @basename ||= @ttf.name.postscript_name
      end

      # not sure how to compute this for true-type fonts...
      def stem_v
        0
      end

      def italic_angle
        return @italic_angle if @italic_angle

        if @ttf.postscript.exists?
          raw = @ttf.postscript.italic_angle
          hi = raw >> 16
          low = raw & 0xFF
          hi = -((hi ^ 0xFFFF) + 1) if hi & 0x8000 != 0
          @italic_angle = "#{hi}.#{low}".to_f
        else
          @italic_angle = 0
        end

        @italic_angle
      end

      def cap_height
        @cap_height ||= begin
          height = @ttf.os2.exists? && @ttf.os2.cap_height || 0
          height.zero? ? @ascender : height
        end
      end

      def x_height
        # FIXME: seems like if os2 table doesn't exist, we could
        # just find the height of the lower-case 'x' glyph?
        @ttf.os2.exists? && @ttf.os2.x_height || 0
      end

      def family_class
        @family_class ||= (@ttf.os2.exists? && @ttf.os2.family_class || 0) >> 8
      end

      def serif?
        @serif ||= [1, 2, 3, 4, 5, 7].include?(family_class)
      end

      def script?
        @script ||= family_class == 10
      end

      def pdf_flags
        @pdf_flags ||= begin
          flags = 0
          flags |= 0x0001 if @ttf.postscript.fixed_pitch?
          flags |= 0x0002 if serif?
          flags |= 0x0008 if script?
          flags |= 0x0040 if italic_angle != 0
          # Assume the font contains at least some non-latin characters
          flags | 0x0004
        end
      end

      def normalize_encoding(text)
        text.encode(::Encoding::UTF_8)
      rescue StandardError => e
        puts e
        raise Prawn::Errors::IncompatibleStringEncoding, 'Encoding ' \
          "#{text.encoding} can not be transparently converted to UTF-8. " \
          'Please ensure the encoding of the string you are attempting ' \
          'to use is set correctly'
      end

      def to_utf8(text)
        text.encode('UTF-8')
      end

      def glyph_present?(char)
        code = char.codepoints.first
        cmap[code].positive?
      end

      # Returns the number of characters in +str+ (a UTF-8-encoded string).
      #
      def character_count(str)
        str.length
      end

      private

      def cmap
        (@cmap ||= @ttf.cmap.unicode.first) || raise('no unicode cmap for font')
      end

      # +string+ must be UTF8-encoded.
      #
      # Returns an array. If an element is a numeric, it represents the
      # kern amount to inject at that position. Otherwise, the element
      # is an array of UTF-16 characters.
      def kern(string)
        a = []

        string.each_codepoint do |r|
          if a.empty?
            a << [r]
          elsif (kern = kern_pairs_table[[cmap[a.last.last], cmap[r]]])
            kern *= scale_factor
            a << -kern << [r]
          else
            a.last << r
          end
        end

        a
      end

      def kern_pairs_table
        @kern_pairs_table ||=
          if has_kerning_data?
            @ttf.kerning.tables.first.pairs
          else
            {}
          end
      end

      def hmtx
        @hmtx ||= @ttf.horizontal_metrics
      end

      def character_width_by_code(code)
        return 0 unless cmap[code]

        # Some TTF fonts have nonzero widths for \n (UTF-8 / ASCII code: 10).
        # Patch around this as we'll never be drawing a newline with a width.
        return 0.0 if code == 10

        @char_widths[code] ||= Integer(hmtx.widths[cmap[code]] * scale_factor)
      end

      def scale_factor
        @scale_factor ||= 1000.0 / @ttf.header.units_per_em
      end

      def register(subset)
        temp_name = @ttf.name.postscript_name.delete("\0").to_sym
        ref = @document.ref!(Type: :Font, BaseFont: temp_name)

        # Embed the font metrics in the document after everything has been
        # drawn, just before the document is emitted.
        @document.renderer.before_render { |_doc| embed(ref, subset) }

        ref
      end

      def embed(reference, subset)
        font_content = @subsets[subset].encode

        # FIXME: we need postscript_name and glyph widths from the font
        # subset. Perhaps this could be done by querying the subset,
        # rather than by parsing the font that the subset produces?
        font = TTFunk::File.new(font_content)

        # empirically, it looks like Adobe Reader will not display fonts
        # if their font name is more than 33 bytes long. Strange. But true.
        basename = font.name.postscript_name[0, 33].delete("\0")

        raise "Can't detect a postscript name for #{file}" if basename.nil?

        fontfile = @document.ref!(Length1: font_content.size)
        fontfile.stream << font_content
        fontfile.stream.compress!

        descriptor = @document.ref!(
          Type: :FontDescriptor,
          FontName: basename.to_sym,
          FontFile2: fontfile,
          FontBBox: bbox,
          Flags: pdf_flags,
          StemV: stem_v,
          ItalicAngle: italic_angle,
          Ascent: @ascender,
          Descent: @descender,
          CapHeight: cap_height,
          XHeight: x_height
        )

        hmtx = font.horizontal_metrics
        widths = font.cmap.tables.first.code_map.map do |gid|
          Integer(hmtx.widths[gid] * scale_factor)
        end[32..-1]

        # It would be nice to have Encoding set for the macroman subsets,
        # and only do a ToUnicode cmap for non-encoded unicode subsets.
        # However, apparently Adobe Reader won't render MacRoman encoded
        # subsets if original font contains unicode characters. (It has to
        # be some flag or something that ttfunk is simply copying over...
        # but I can't figure out which flag that is.)
        #
        # For now, it's simplest to just create a unicode cmap for every font.
        # It offends my inner purist, but it'll do.

        map = @subsets[subset].to_unicode_map

        ranges = [[]]
        map.keys.sort.inject('') do |_s, code|
          ranges << [] if ranges.last.length >= 100
          unicode = map[code]
          ranges.last << format(
            '<%<code>02x><%<unicode>04x>',
            code: code,
            unicode: unicode
          )
        end

        range_blocks = ranges.inject(+'') do |s, list|
          s << format(
            "%<lenght>d beginbfchar\n%<list>s\nendbfchar\n",
            lenght: list.length,
            list: list.join("\n")
          )
        end

        to_unicode_cmap = UNICODE_CMAP_TEMPLATE % range_blocks.strip

        cmap = @document.ref!({})
        cmap << to_unicode_cmap
        cmap.stream.compress!

        reference.data.update(
          Subtype: :TrueType,
          BaseFont: basename.to_sym,
          FontDescriptor: descriptor,
          FirstChar: 32,
          LastChar: 255,
          Widths: @document.ref!(widths),
          ToUnicode: cmap
        )
      end

      UNICODE_CMAP_TEMPLATE = <<-STR.strip.gsub(/^\s*/, '')
        /CIDInit /ProcSet findresource begin
        12 dict begin
        begincmap
        /CIDSystemInfo <<
          /Registry (Adobe)
          /Ordering (UCS)
          /Supplement 0
        >> def
        /CMapName /Adobe-Identity-UCS def
        /CMapType 2 def
        1 begincodespacerange
        <00><ff>
        endcodespacerange
        %s
        endcmap
        CMapName currentdict /CMap defineresource pop
        end
        end
      STR

      def read_ttf_file
        TTFunk::File.open(@name)
      end
    end
  end
end

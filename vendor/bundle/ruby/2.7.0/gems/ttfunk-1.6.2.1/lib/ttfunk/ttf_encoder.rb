# frozen_string_literal: true

module TTFunk
  class TTFEncoder
    OPTIMAL_TABLE_ORDER = [
      'head', 'hhea', 'maxp', 'OS/2', 'hmtx', 'LTSH', 'VDMX',
      'hdmx', 'cmap', 'fpgm', 'prep', 'cvt ', 'loca', 'glyf',
      'kern', 'name', 'post', 'gasp', 'PCLT'
    ].freeze

    attr_reader :original, :subset, :options

    def initialize(original, subset, options = {})
      @original = original
      @subset = subset
      @options = options
    end

    def encode
      # https://www.microsoft.com/typography/otspec/otff.htm#offsetTable
      search_range = 2**Math.log2(tables.length).floor * 16
      entry_selector = Math.log2(2**Math.log2(tables.length).floor).to_i
      range_shift = tables.length * 16 - search_range
      range_shift = 0 if range_shift < 0

      newfont = EncodedString.new

      newfont << [
        original.directory.scaler_type,
        tables.length,
        search_range,
        entry_selector,
        range_shift
      ].pack('Nn*')

      # Tables are supposed to be listed in ascending order whereas there is a
      # known optimal order for table data.
      tables.keys.sort.each do |tag|
        newfont << [tag, checksum(tables[tag])].pack('A4N')
        newfont << Placeholder.new(tag, length: 4)
        newfont << [tables[tag].length].pack('N')
      end

      optimal_table_order.each do |optimal_tag|
        next unless tables.include?(optimal_tag)

        newfont.resolve_placeholder(optimal_tag, [newfont.length].pack('N'))
        newfont << tables[optimal_tag]
        newfont.align!(4)
      end

      sum = checksum(newfont)
      adjustment = 0xB1B0AFBA - sum
      newfont.resolve_placeholder(:checksum, [adjustment].pack('N'))

      newfont.string
    end

    private

    def optimal_table_order
      OPTIMAL_TABLE_ORDER +
        (tables.keys - ['DSIG'] - OPTIMAL_TABLE_ORDER) +
        ['DSIG']
    end

    # "mandatory" tables. Every font should ("should") have these

    def cmap_table
      @cmap_table ||= subset.new_cmap_table
    end

    def glyf_table
      @glyf_table ||= TTFunk::Table::Glyf.encode(
        glyphs, new_to_old_glyph, old_to_new_glyph
      )
    end

    def loca_table
      @loca_table ||= TTFunk::Table::Loca.encode(
        glyf_table[:offsets]
      )
    end

    def hmtx_table
      @hmtx_table ||= TTFunk::Table::Hmtx.encode(
        original.horizontal_metrics, new_to_old_glyph
      )
    end

    def hhea_table
      @hhea_table = TTFunk::Table::Hhea.encode(
        original.horizontal_header, hmtx_table, original, new_to_old_glyph
      )
    end

    def maxp_table
      @maxp_table ||= TTFunk::Table::Maxp.encode(
        original.maximum_profile, old_to_new_glyph
      )
    end

    def post_table
      @post_table ||= TTFunk::Table::Post.encode(
        original.postscript, new_to_old_glyph
      )
    end

    def name_table
      @name_table ||= TTFunk::Table::Name.encode(
        original.name, glyf_table.fetch(:table, '')
      )
    end

    def head_table
      @head_table ||= TTFunk::Table::Head.encode(
        original.header, loca_table, new_to_old_glyph
      )
    end

    # "optional" tables. Fonts may omit these if they do not need them.
    # Because they apply globally, we can simply copy them over, without
    # modification, if they exist.

    def os2_table
      @os2_table ||= TTFunk::Table::OS2.encode(original.os2, subset)
    end

    def cvt_table
      @cvt_table ||= TTFunk::Table::Simple.new(original, 'cvt ').raw
    end

    def fpgm_table
      @fpgm_table ||= TTFunk::Table::Simple.new(original, 'fpgm').raw
    end

    def prep_table
      @prep_table ||= TTFunk::Table::Simple.new(original, 'prep').raw
    end

    def gasp_table
      @gasp_table ||= TTFunk::Table::Simple.new(original, 'gasp').raw
    end

    def kern_table
      # for PDFs, the kerning info is all included in the PDF as the text is
      # drawn. Thus, the PDF readers do not actually use the kerning info in
      # embedded fonts. If the library is used for something else, the
      # generated subfont may need a kerning table... in that case, you need
      # to opt into it.
      if options[:kerning]
        @kern_table ||= TTFunk::Table::Kern.encode(
          original.kerning, old_to_new_glyph
        )
      end
    end

    def vorg_table
      @vorg_table ||= TTFunk::Table::Vorg.encode(
        original.vertical_origins
      )
    end

    def dsig_table
      @dsig_table ||= TTFunk::Table::Dsig.encode(
        original.digital_signature
      )
    end

    def tables
      @tables ||= {
        'cmap' => cmap_table[:table],
        'glyf' => glyf_table[:table],
        'loca' => loca_table[:table],
        'kern' => kern_table,
        'hmtx' => hmtx_table[:table],
        'hhea' => hhea_table,
        'maxp' => maxp_table,
        'OS/2' => os2_table,
        'post' => post_table,
        'name' => name_table,
        'head' => head_table,
        'prep' => prep_table,
        'fpgm' => fpgm_table,
        'cvt ' => cvt_table,
        'VORG' => vorg_table,
        'DSIG' => dsig_table,
        'gasp' => gasp_table
      }.reject { |_tag, table| table.nil? }
    end

    def glyphs
      subset.glyphs
    end

    def new_to_old_glyph
      subset.new_to_old_glyph
    end

    def old_to_new_glyph
      subset.old_to_new_glyph
    end

    def checksum(data)
      align(raw(data), 4).unpack('N*').reduce(0, :+) & 0xFFFF_FFFF
    end

    def raw(data)
      data.respond_to?(:unresolved_string) ? data.unresolved_string : data
    end

    def align(data, width)
      if data.length % width > 0
        data + "\0" * (width - data.length % width)
      else
        data
      end
    end
  end
end

# frozen_string_literal: true

require 'stringio'
require 'pathname'

require_relative 'ttfunk/aggregate'
require_relative 'ttfunk/directory'
require_relative 'ttfunk/resource_file'
require_relative 'ttfunk/collection'
require_relative 'ttfunk/ttf_encoder'
require_relative 'ttfunk/encoded_string'
require_relative 'ttfunk/placeholder'
require_relative 'ttfunk/otf_encoder'
require_relative 'ttfunk/sci_form'
require_relative 'ttfunk/bit_field'
require_relative 'ttfunk/bin_utils'
require_relative 'ttfunk/sub_table'
require_relative 'ttfunk/min'
require_relative 'ttfunk/max'
require_relative 'ttfunk/sum'
require_relative 'ttfunk/one_based_array'

module TTFunk
  class File
    attr_reader :contents
    attr_reader :directory

    def self.open(io_or_path)
      new verify_and_open(io_or_path).read
    end

    def self.from_dfont(file, which = 0)
      new(ResourceFile.open(file) { |dfont| dfont['sfnt', which] })
    end

    def self.from_ttc(file, which = 0)
      Collection.open(file) { |ttc| ttc[which] }
    end

    def self.verify_and_open(io_or_path)
      # File or IO
      if io_or_path.respond_to?(:rewind)
        io = io_or_path
        # Rewind if the object we're passed is an IO, so that multiple embeds of
        # the same IO object will work
        io.rewind
        # read the file as binary so the size is calculated correctly
        # guard binmode because some objects acting io-like don't implement it
        io.binmode if io.respond_to?(:binmode)
        return io
      end
      # String or Pathname
      io_or_path = Pathname.new(io_or_path)
      raise ArgumentError, "#{io_or_path} not found" unless io_or_path.file?

      io = io_or_path.open('rb')
      io
    end

    def initialize(contents, offset = 0)
      @contents = StringIO.new(contents)
      @directory = Directory.new(@contents, offset)
    end

    def ascent
      @ascent ||= (os2.exists? && os2.ascent && os2.ascent.nonzero?) ||
        horizontal_header.ascent
    end

    def descent
      @descent ||= (os2.exists? && os2.descent && os2.descent.nonzero?) ||
        horizontal_header.descent
    end

    def line_gap
      @line_gap ||= (os2.exists? && os2.line_gap && os2.line_gap.nonzero?) ||
        horizontal_header.line_gap
    end

    def bbox
      [header.x_min, header.y_min, header.x_max, header.y_max]
    end

    def directory_info(tag)
      directory.tables[tag.to_s]
    end

    def header
      @header ||= TTFunk::Table::Head.new(self)
    end

    def cmap
      @cmap ||= TTFunk::Table::Cmap.new(self)
    end

    def horizontal_header
      @horizontal_header ||= TTFunk::Table::Hhea.new(self)
    end

    def horizontal_metrics
      @horizontal_metrics ||= TTFunk::Table::Hmtx.new(self)
    end

    def maximum_profile
      @maximum_profile ||= TTFunk::Table::Maxp.new(self)
    end

    def kerning
      @kerning ||= TTFunk::Table::Kern.new(self)
    end

    def name
      @name ||= TTFunk::Table::Name.new(self)
    end

    def os2
      @os2 ||= TTFunk::Table::OS2.new(self)
    end

    def postscript
      @postscript ||= TTFunk::Table::Post.new(self)
    end

    def glyph_locations
      @glyph_locations ||= TTFunk::Table::Loca.new(self)
    end

    def glyph_outlines
      @glyph_outlines ||= TTFunk::Table::Glyf.new(self)
    end

    def sbix
      @sbix ||= TTFunk::Table::Sbix.new(self)
    end

    def cff
      @cff ||= TTFunk::Table::Cff.new(self)
    end

    def vertical_origins
      @vertical_origins ||=
        if directory.tables.include?(TTFunk::Table::Vorg::TAG)
          TTFunk::Table::Vorg.new(self)
        end
    end

    def digital_signature
      @digital_signature ||=
        if directory.tables.include?(TTFunk::Table::Dsig::TAG)
          TTFunk::Table::Dsig.new(self)
        end
    end

    def find_glyph(glyph_id)
      if cff.exists?
        cff.top_index[0].charstrings_index[glyph_id].glyph
      else
        glyph_outlines.for(glyph_id)
      end
    end
  end
end

require_relative 'ttfunk/table/cff'
require_relative 'ttfunk/table/cmap'
require_relative 'ttfunk/table/dsig'
require_relative 'ttfunk/table/glyf'
require_relative 'ttfunk/table/head'
require_relative 'ttfunk/table/hhea'
require_relative 'ttfunk/table/hmtx'
require_relative 'ttfunk/table/kern'
require_relative 'ttfunk/table/loca'
require_relative 'ttfunk/table/maxp'
require_relative 'ttfunk/table/name'
require_relative 'ttfunk/table/os2'
require_relative 'ttfunk/table/post'
require_relative 'ttfunk/table/sbix'
require_relative 'ttfunk/table/vorg'

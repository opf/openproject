# frozen_string_literal: true

# Implements AFM font support for Prawn
#
# Copyright May 2008, Gregory Brown / James Healy.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

require_relative '../encoding'

module Prawn
  module Fonts
    # @private

    class AFM < Font
      class << self
        attr_accessor :hide_m17n_warning
      end

      self.hide_m17n_warning = false

      BUILT_INS = %w[
        Courier Helvetica Times-Roman Symbol ZapfDingbats
        Courier-Bold Courier-Oblique Courier-BoldOblique
        Times-Bold Times-Italic Times-BoldItalic
        Helvetica-Bold Helvetica-Oblique Helvetica-BoldOblique
      ].freeze

      def unicode?
        false
      end

      def self.metrics_path
        @metrics_path ||= if ENV['METRICS']
                            ENV['METRICS'].split(':')
                          else
                            [
                              '.', '/usr/lib/afm',
                              '/usr/local/lib/afm',
                              '/usr/openwin/lib/fonts/afm',
                              Prawn::DATADIR + '/fonts'
                            ]
                          end
      end

      attr_reader :attributes #:nodoc:

      # parse each ATM font file once only
      def self.font_data
        @font_data ||= SynchronizedCache.new
      end

      def initialize(document, name, options = {}) #:nodoc:
        name ||= options[:family]
        unless BUILT_INS.include?(name)
          raise Prawn::Errors::UnknownFont,
            "#{name} (#{options[:style] || 'normal'}) is not a known font."
        end

        super

        file_name = @name.dup
        file_name << '.afm' unless /\.afm$/.match?(file_name)
        file_name = file_name[0] == '/' ? file_name : find_font(file_name)

        font_data = self.class.font_data[file_name] ||= parse_afm(file_name)
        @glyph_widths = font_data[:glyph_widths]
        @glyph_table = font_data[:glyph_table]
        @bounding_boxes = font_data[:bounding_boxes]
        @kern_pairs = font_data[:kern_pairs]
        @kern_pair_table = font_data[:kern_pair_table]
        @attributes = font_data[:attributes]

        @ascender = @attributes['ascender'].to_i
        @descender = @attributes['descender'].to_i
        @line_gap = Float(bbox[3] - bbox[1]) - (@ascender - @descender)
      end

      # The font bbox, as an array of integers
      #
      def bbox
        @bbox ||= @attributes['fontbbox'].split(/\s+/).map { |e| Integer(e) }
      end

      # NOTE: String *must* be encoded as WinAnsi
      def compute_width_of(string, options = {}) #:nodoc:
        scale = (options[:size] || size) / 1000.0

        if options[:kerning]
          strings, numbers = kern(string).partition { |e| e.is_a?(String) }
          total_kerning_offset = numbers.inject(0.0) { |a, e| a + e }
          (unscaled_width_of(strings.join) - total_kerning_offset) * scale
        else
          unscaled_width_of(string) * scale
        end
      end

      # Returns true if the font has kerning data, false otherwise
      #
      # rubocop: disable Naming/PredicateName
      def has_kerning_data?
        @kern_pairs.any?
      end
      # rubocop: enable Naming/PredicateName

      # built-in fonts only work with winansi encoding, so translate the
      # string. Changes the encoding in-place, so the argument itself
      # is replaced with a string in WinAnsi encoding.
      #
      def normalize_encoding(text)
        text.encode('windows-1252')
      rescue ::Encoding::InvalidByteSequenceError,
             ::Encoding::UndefinedConversionError

        raise Prawn::Errors::IncompatibleStringEncoding,
          "Your document includes text that's not compatible with the " \
          "Windows-1252 character set.\n" \
          'If you need full UTF-8 support, use external fonts instead of ' \
          "PDF's built-in fonts.\n"
      end

      def to_utf8(text)
        text.encode('UTF-8')
      end

      # Returns the number of characters in +str+ (a WinAnsi-encoded string).
      #
      def character_count(str)
        str.length
      end

      # Perform any changes to the string that need to happen
      # before it is rendered to the canvas. Returns an array of
      # subset "chunks", where each chunk is an array of two elements.
      # The first element is the font subset number, and the second
      # is either a string or an array (for kerned text).
      #
      # For Adobe fonts, there is only ever a single subset, so
      # the first element of the array is "0", and the second is
      # the string itself (or an array, if kerning is performed).
      #
      # The +text+ parameter must be in WinAnsi encoding (cp1252).
      #
      def encode_text(text, options = {})
        [[0, options[:kerning] ? kern(text) : text]]
      end

      def glyph_present?(char)
        !normalize_encoding(char).nil?
      rescue Prawn::Errors::IncompatibleStringEncoding
        false
      end

      private

      def register(_subset)
        font_dict = {
          Type: :Font,
          Subtype: :Type1,
          BaseFont: name.to_sym
        }

        # Symbolic AFM fonts (Symbol, ZapfDingbats) have their own encodings
        font_dict[:Encoding] = :WinAnsiEncoding unless symbolic?

        @document.ref!(font_dict)
      end

      def symbolic?
        attributes['characterset'] == 'Special'
      end

      def find_font(file)
        self.class.metrics_path.find { |f| File.exist? "#{f}/#{file}" } +
          "/#{file}"
      rescue NoMethodError
        raise Prawn::Errors::UnknownFont,
          "Couldn't find the font: #{file} in any of:\n" +
          self.class.metrics_path.join("\n")
      end

      def parse_afm(file_name)
        data = {
          glyph_widths: {},
          bounding_boxes: {},
          kern_pairs: {},
          attributes: {}
        }
        section = []

        File.foreach(file_name) do |line|
          case line
          when /^Start(\w+)/
            section.push Regexp.last_match(1)
            next
          when /^End(\w+)/
            section.pop
            next
          end

          case section
          when %w[FontMetrics CharMetrics]
            next unless /^CH?\s/.match?(line)

            name = line[/\bN\s+(\.?\w+)\s*;/, 1]
            data[:glyph_widths][name] = line[/\bWX\s+(\d+)\s*;/, 1].to_i
            data[:bounding_boxes][name] = line[/\bB\s+([^;]+);/, 1].to_s.rstrip
          when %w[FontMetrics KernData KernPairs]
            next unless line =~ /^KPX\s+(\.?\w+)\s+(\.?\w+)\s+(-?\d+)/

            data[:kern_pairs][[Regexp.last_match(1), Regexp.last_match(2)]] =
              Regexp.last_match(3).to_i
          when %w[FontMetrics KernData TrackKern],
            %w[FontMetrics Composites]
            next
          else
            parse_generic_afm_attribute(line, data)
          end
        end

        # process data parsed from AFM file to build tables which
        #   will be used when measuring and kerning text
        data[:glyph_table] = (0..255).map do |i|
          data[:glyph_widths][Encoding::WinAnsi::CHARACTERS[i]].to_i
        end

        character_hash = Hash[
          Encoding::WinAnsi::CHARACTERS.zip(
            (0..Encoding::WinAnsi::CHARACTERS.size).to_a
          )
        ]
        data[:kern_pair_table] =
          data[:kern_pairs].each_with_object({}) do |p, h|
            h[p[0].map { |n| character_hash[n] }] = p[1]
          end

        data.each_value(&:freeze)
        data.freeze
      end

      def parse_generic_afm_attribute(line, hash)
        line =~ /(^\w+)\s+(.*)/
        key = Regexp.last_match(1).to_s.downcase
        value = Regexp.last_match(2)

        hash[:attributes][key] =
          if hash[:attributes][key]
            Array(hash[:attributes][key]) << value
          else
            value
          end
      end

      # converts a string into an array with spacing offsets
      # bewteen characters that need to be kerned
      #
      # String *must* be encoded as WinAnsi
      #
      def kern(string)
        kerned = [[]]
        last_byte = nil

        string.each_byte do |byte|
          k = last_byte && @kern_pair_table[[last_byte, byte]]
          if k
            kerned << -k << [byte]
          else
            kerned.last << byte
          end
          last_byte = byte
        end

        kerned.map do |e|
          e = e.is_a?(Array) ? e.pack('C*') : e
          if e.respond_to?(:force_encoding)
            e.force_encoding(::Encoding::Windows_1252)
          else
            e
          end
        end
      end

      def unscaled_width_of(string)
        string.bytes.inject(0) do |s, r|
          s + @glyph_table[r]
        end
      end
    end
  end
end

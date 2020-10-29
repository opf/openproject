# frozen_string_literal: true

require 'set'

require_relative 'base'

module TTFunk
  module Subset
    class CodePage < Base
      class << self
        def unicode_mapping_for(encoding)
          mapping_cache[encoding] ||= (0..255).each_with_object({}) do |c, ret|
            # rubocop:disable Lint/SuppressedException
            begin
              ret[c] = c.chr(encoding)
                        .encode(Encoding::UTF_8)
                        .codepoints
                        .first
            rescue Encoding::UndefinedConversionError
              # There is not a strict 1:1 mapping between all code page
              # characters and unicode.
            end
            # rubocop:enable Lint/SuppressedException
          end
        end

        private

        def mapping_cache
          @mapping_cache ||= {}
        end
      end

      attr_reader :code_page, :encoding

      def initialize(original, code_page, encoding)
        super(original)
        @code_page = code_page
        @encoding = encoding
        @subset = Array.new(256)
        use(space_char_code)
      end

      def to_unicode_map
        self.class.unicode_mapping_for(encoding)
      end

      def use(character)
        @subset[from_unicode(character)] = character
      end

      def covers?(character)
        !from_unicode(character).nil?
      end

      def includes?(character)
        code = from_unicode(character)
        code && @subset[code]
      end

      def from_unicode(character)
        [character].pack('U*').encode(encoding).ord
      rescue Encoding::UndefinedConversionError
        nil
      end

      def new_cmap_table
        @new_cmap_table ||= begin
          mapping = {}

          @subset.each_with_index do |unicode, roman|
            mapping[roman] = unicode_cmap[unicode]
          end

          TTFunk::Table::Cmap.encode(mapping, :mac_roman)
        end
      end

      def original_glyph_ids
        ([0] + @subset.map { |unicode| unicode && unicode_cmap[unicode] })
          .compact.uniq.sort
      end

      def space_char_code
        @space_char_code ||= from_unicode(Unicode::SPACE_CHAR)
      end
    end
  end
end

# frozen_string_literal: true

require_relative '../table/cmap'
require_relative '../table/glyf'
require_relative '../table/head'
require_relative '../table/hhea'
require_relative '../table/hmtx'
require_relative '../table/kern'
require_relative '../table/loca'
require_relative '../table/maxp'
require_relative '../table/name'
require_relative '../table/post'
require_relative '../table/simple'

module TTFunk
  module Subset
    class Base
      MICROSOFT_PLATFORM_ID = 3
      MS_SYMBOL_ENCODING_ID = 0

      attr_reader :original

      def initialize(original)
        @original = original
      end

      def unicode?
        false
      end

      def microsoft_symbol?
        new_cmap_table[:platform_id] == MICROSOFT_PLATFORM_ID &&
          new_cmap_table[:encoding_id] == MS_SYMBOL_ENCODING_ID
      end

      def to_unicode_map
        {}
      end

      def encode(options = {})
        encoder_klass.new(original, self, options).encode
      end

      def encoder_klass
        original.cff.exists? ? OTFEncoder : TTFEncoder
      end

      def unicode_cmap
        @unicode_cmap ||= @original.cmap.unicode.first
      end

      def glyphs
        @glyphs ||= collect_glyphs(original_glyph_ids)
      end

      def collect_glyphs(glyph_ids)
        collected = glyph_ids.each_with_object({}) do |id, h|
          h[id] = glyph_for(id)
        end

        additional_ids = collected.values
                                  .select { |g| g && g.compound? }
                                  .map(&:glyph_ids)
                                  .flatten

        collected.update(collect_glyphs(additional_ids)) if additional_ids.any?

        collected
      end

      def old_to_new_glyph
        @old_to_new_glyph ||= begin
          charmap = new_cmap_table[:charmap]
          old_to_new = charmap.each_with_object(0 => 0) do |(_, ids), map|
            map[ids[:old]] = ids[:new]
          end

          next_glyph_id = new_cmap_table[:max_glyph_id]

          glyphs.keys.each do |old_id|
            unless old_to_new.key?(old_id)
              old_to_new[old_id] = next_glyph_id
              next_glyph_id += 1
            end
          end

          old_to_new
        end
      end

      def new_to_old_glyph
        @new_to_old_glyph ||= old_to_new_glyph.invert
      end

      private

      def glyph_for(glyph_id)
        if original.cff.exists?
          original
            .cff
            .top_index[0]
            .charstrings_index[glyph_id]
            .glyph
        else
          original.glyph_outlines.for(glyph_id)
        end
      end
    end
  end
end

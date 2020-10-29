# frozen_string_literal: true

require 'set'
require_relative 'base'

module TTFunk
  module Subset
    class Unicode < Base
      SPACE_CHAR = 0x20

      def initialize(original)
        super
        @subset = Set.new
        use(SPACE_CHAR)
      end

      def unicode?
        true
      end

      def to_unicode_map
        @subset.each_with_object({}) { |code, map| map[code] = code }
      end

      def use(character)
        @subset << character
      end

      def covers?(_character)
        true
      end

      def includes?(character)
        @subset.include?(character)
      end

      def from_unicode(character)
        character
      end

      def new_cmap_table
        @new_cmap_table ||= begin
          mapping = @subset.each_with_object({}) do |code, map|
            map[code] = unicode_cmap[code]
          end

          TTFunk::Table::Cmap.encode(mapping, :unicode)
        end
      end

      def original_glyph_ids
        ([0] + @subset.map { |code| unicode_cmap[code] }).uniq.sort
      end
    end
  end
end

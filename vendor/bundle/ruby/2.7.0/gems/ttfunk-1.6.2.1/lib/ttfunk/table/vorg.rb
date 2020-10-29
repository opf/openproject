# frozen_string_literal: true

require_relative '../table'

module TTFunk
  class Table
    class Vorg < Table
      TAG = 'VORG'

      attr_reader :major_version, :minor_version
      attr_reader :default_vert_origin_y, :count

      def self.encode(vorg)
        return nil unless vorg

        ''.b.tap do |table|
          table << [
            vorg.major_version, vorg.minor_version,
            vorg.default_vert_origin_y, vorg.count
          ].pack('n*')

          vorg.origins.each_pair do |glyph_id, vert_origin_y|
            table << [glyph_id, vert_origin_y].pack('n*')
          end
        end
      end

      def for(glyph_id)
        @origins.fetch(glyph_id, default_vert_origin_y)
      end

      def tag
        TAG
      end

      def origins
        @origins ||= {}
      end

      private

      def parse!
        @major_version, @minor_version = read(4, 'n*')
        @default_vert_origin_y = read_signed(1).first
        @count = read(2, 'n').first

        count.times do
          glyph_id = read(2, 'n').first
          origins[glyph_id] = read_signed(1).first
        end
      end
    end
  end
end

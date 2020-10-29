# frozen_string_literal: true

module Prawn
  module Markup
    class SizeConverter
      attr_reader :max

      def initialize(max)
        @max = max
      end

      def parse(width)
        return nil if width.to_s.strip.empty? || width.to_s == 'auto'

        points = convert(width)
        max ? [points, max].min : points
      end

      def convert(string)
        value = string.to_f
        if string.end_with?('%')
          value * max / 100.0
        elsif string.end_with?('cm')
          value.cm
        elsif string.end_with?('mm')
          value.mm
        else
          value
        end
      end
    end
  end
end

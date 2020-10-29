# frozen_string_literal: true

# cap_style.rb : Implements stroke cap styling
#
# Contributed by Daniel Nelson. October, 2009
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
module Prawn
  module Graphics
    module CapStyle
      # @group Stable API

      CAP_STYLES = { butt: 0, round: 1, projecting_square: 2 }.freeze

      # Sets the cap style for stroked lines and curves
      #
      # style is one of :butt, :round, or :projecting_square
      #
      # NOTE: If this method is never called, :butt will be used by default.
      #
      def cap_style(style = nil)
        return current_cap_style || :butt if style.nil?

        self.current_cap_style = style

        write_stroke_cap_style
      end

      alias cap_style= cap_style

      private

      def current_cap_style
        graphic_state.cap_style
      end

      def current_cap_style=(style)
        graphic_state.cap_style = style
      end

      def write_stroke_cap_style
        renderer.add_content "#{CAP_STYLES[current_cap_style]} J"
      end
    end
  end
end

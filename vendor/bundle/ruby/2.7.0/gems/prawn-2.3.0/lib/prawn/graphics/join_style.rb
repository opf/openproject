# frozen_string_literal: true

# join_style.rb : Implements stroke join styling
#
# Contributed by Daniel Nelson. October, 2009
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
module Prawn
  module Graphics
    module JoinStyle
      JOIN_STYLES = { miter: 0, round: 1, bevel: 2 }.freeze

      # @group Stable API

      # Sets the join style for stroked lines and curves
      #
      # style is one of :miter, :round, or :bevel
      #
      # NOTE: if this method is never called, :miter will be used for join style
      # throughout the document
      #
      def join_style(style = nil)
        return current_join_style || :miter if style.nil?

        self.current_join_style = style

        unless JOIN_STYLES.key?(current_join_style)
          raise Prawn::Errors::InvalidJoinStyle,
            "#{style} is not a recognized join style. Valid styles are " +
            JOIN_STYLES.keys.join(', ')
        end

        write_stroke_join_style
      end

      alias join_style= join_style

      private

      def current_join_style
        graphic_state.join_style
      end

      def current_join_style=(style)
        graphic_state.join_style = style
      end

      def write_stroke_join_style
        renderer.add_content "#{JOIN_STYLES[current_join_style]} j"
      end
    end
  end
end

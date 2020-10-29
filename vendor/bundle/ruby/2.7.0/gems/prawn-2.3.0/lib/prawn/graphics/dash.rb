# frozen_string_literal: true

# dash.rb : Implements stroke dashing
#
# Contributed by Daniel Nelson. October, 2009
#
# This is free software. Please see the LICENSE and COPYING files for details.
#
module Prawn
  module Graphics
    module Dash
      # @group Stable API

      # Sets the dash pattern for stroked lines and curves or return the
      # current dash pattern setting if +length+ is nil.
      #
      # There are two ways to set the dash pattern:
      #
      # * If the parameter +length+ is an Integer/Float, it specifies
      #   the length of the dash and of the gap. The length of the gap
      #   can be customized by setting the :space option.
      #
      #   Examples:
      #
      #     length = 3
      #       3 on, 3 off, 3 on, 3 off, ...
      #     length = 3, :space =2
      #       3 on, 2 off, 3 on, 2 off, ...
      #
      # * If the parameter +length+ is an array, it specifies the
      #   lengths of alternating dashes and gaps. The numbers must be
      #   non-negative and not all zero. The :space option is ignored
      #   in this case.
      #
      #   Examples:
      #
      #     length = [2, 1]
      #       2 on, 1 off, 2 on, 1 off, ...
      #     length = [3, 1, 2, 3]
      #       3 on, 1 off, 2 on, 3 off, 3 on, 1 off, ...
      #     length = [3, 0, 1]
      #       3 on, 0 off, 1 on, 3 off, 0 on, 1 off, ...
      #
      # Options may contain the keys :space and :phase
      #
      # :space:: The space between the dashes (only used when +length+
      #          is not an array)
      #
      # :phase:: The distance into the dash pattern at which to start
      #          the dash. For example, a phase of 0 starts at the
      #          beginning of the dash; whereas, if the phase is equal
      #          to the length of the dash, then stroking will begin at
      #          the beginning of the space. Default is 0.
      #
      # Integers or Floats may be used for length and the option values.
      # Dash units are in PDF points (1/72 inch).
      #
      def dash(length = nil, options = {})
        return current_dash_state if length.nil?

        length = Array(length)

        if length.all?(&:zero?)
          raise ArgumentError,
            'Zero length dashes are invalid. Call #undash to disable dashes.'
        elsif length.any?(&:negative?)
          raise ArgumentError,
            'Negative numbers are not allowed for dash lengths.'
        end

        length = length.first if length.length == 1

        self.current_dash_state = {
          dash: length,
          space: length.is_a?(Array) ? nil : options[:space] || length,
          phase: options[:phase] || 0
        }

        write_stroke_dash
      end

      alias dash= dash

      # Stops dashing, restoring solid stroked lines and curves
      #
      def undash
        self.current_dash_state = undashed_setting
        write_stroke_dash
      end

      # Returns when stroke is dashed, false otherwise
      #
      def dashed?
        current_dash_state != undashed_setting
      end

      private

      def write_stroke_dash
        renderer.add_content dash_setting
      end

      def undashed_setting
        { dash: nil, space: nil, phase: 0 }
      end

      def current_dash_state=(dash_options)
        graphic_state.dash = dash_options
      end

      def current_dash_state
        graphic_state.dash
      end

      def dash_setting
        graphic_state.dash_setting
      end
    end
  end
end

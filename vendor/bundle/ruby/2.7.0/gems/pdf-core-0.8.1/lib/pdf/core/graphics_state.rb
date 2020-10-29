
# frozen_string_literal: true

#
# Implements graphics state saving and restoring
#
# Copyright January 2010, Michael Witrant. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details
#

module PDF
  module Core
    class GraphicStateStack
      attr_accessor :stack

      def initialize(previous_state = nil)
        self.stack = [GraphicState.new(previous_state)]
      end

      def save_graphic_state(graphic_state = nil)
        stack.push(GraphicState.new(graphic_state || current_state))
      end

      def restore_graphic_state
        if stack.empty?
          raise PDF::Core::Errors::EmptyGraphicStateStack,
            "\n You have reached the end of the graphic state stack"
        end
        stack.pop
      end

      def current_state
        stack.last
      end

      def present?
        !stack.empty?
      end

      def empty?
        stack.empty?
      end
    end

    # NOTE: This class may be a good candidate for a copy-on-write hash.
    class GraphicState
      attr_accessor :color_space, :dash, :cap_style, :join_style, :line_width,
        :fill_color, :stroke_color

      def initialize(previous_state = nil)
        if previous_state
          initialize_copy(previous_state)
        else
          @color_space  = {}
          @fill_color   = '000000'
          @stroke_color = '000000'
          @dash         = { dash: nil, space: nil, phase: 0 }
          @cap_style    = :butt
          @join_style   = :miter
          @line_width   = 1
        end
      end

      def dash_setting
        return '[] 0 d' unless @dash[:dash]

        array = if @dash[:dash].is_a?(Array)
                  @dash[:dash]
                else
                  [@dash[:dash], @dash[:space]]
                end

        "[#{PDF::Core.real_params(array)}] "\
          "#{PDF::Core.real(@dash[:phase])} d"
      end

      private

      def initialize_copy(other)
        # mutable state
        @color_space  = other.color_space.dup
        @fill_color   = other.fill_color.dup
        @stroke_color = other.stroke_color.dup
        @dash         = other.dash.dup

        # immutable state that doesn't need to be duped
        @cap_style    = other.cap_style
        @join_style   = other.join_style
        @line_width   = other.line_width
      end
    end
  end
end

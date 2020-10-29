# frozen_string_literal: true

# text/formatted/fragment.rb : Implements information about a formatted fragment
#
# Copyright March 2010, Daniel Nelson. All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  module Text
    module Formatted
      # Prawn::Text::Formatted::Fragment is a state store for a formatted text
      # fragment. It does not render anything.
      #
      # @private
      class Fragment
        attr_reader :format_state, :text
        attr_writer :width
        attr_accessor :line_height, :descender, :ascender
        attr_accessor :word_spacing, :left, :baseline

        def initialize(text, format_state, document)
          @format_state = format_state
          @document = document
          @word_spacing = 0

          # keep the original value of "text", so we can reinitialize @text if
          # formatting parameters like text direction are changed
          @original_text = text
          @text = process_text(@original_text)
        end

        def width
          if @word_spacing.zero? then @width
          else @width + @word_spacing * space_count
          end
        end

        def height
          top - bottom
        end

        def subscript?
          styles.include?(:subscript)
        end

        def superscript?
          styles.include?(:superscript)
        end

        def y_offset
          if subscript? then -descender
          elsif superscript? then 0.85 * ascender
          else 0
          end
        end

        def bounding_box
          [left, bottom, right, top]
        end

        def absolute_bounding_box
          box = bounding_box
          box[0] += @document.bounds.absolute_left
          box[2] += @document.bounds.absolute_left
          box[1] += @document.bounds.absolute_bottom
          box[3] += @document.bounds.absolute_bottom
          box
        end

        def underline_points
          y = baseline - 1.25
          [[left, y], [right, y]]
        end

        def strikethrough_points
          y = baseline + ascender * 0.3
          [[left, y], [right, y]]
        end

        def styles
          @format_state[:styles] || []
        end

        def link
          @format_state[:link]
        end

        def anchor
          @format_state[:anchor]
        end

        def local
          @format_state[:local]
        end

        def color
          @format_state[:color]
        end

        def font
          @format_state[:font]
        end

        def size
          @format_state[:size]
        end

        def character_spacing
          @format_state[:character_spacing] ||
            @document.character_spacing
        end

        def direction
          @format_state[:direction]
        end

        def default_direction=(direction)
          unless @format_state[:direction]
            @format_state[:direction] = direction
            @text = process_text(@original_text)
          end
        end

        def include_trailing_white_space!
          @format_state.delete(:exclude_trailing_white_space)
          @text = process_text(@original_text)
        end

        def space_count
          @text.count(' ')
        end

        def callback_objects
          callback = @format_state[:callback]
          if callback.nil?
            []
          elsif callback.is_a?(Array)
            callback
          else
            [callback]
          end
        end

        def right
          left + width
        end

        def top
          baseline + ascender
        end

        def bottom
          baseline - descender
        end

        def top_left
          [left, top]
        end

        def top_right
          [right, top]
        end

        def bottom_right
          [right, bottom]
        end

        def bottom_left
          [left, bottom]
        end

        def absolute_left
          absolute_bounding_box[0]
        end

        def absolute_right
          absolute_bounding_box[2]
        end

        def absolute_top
          absolute_bounding_box[3]
        end

        def absolute_bottom
          absolute_bounding_box[1]
        end

        def absolute_top_left
          [absolute_left, absolute_top]
        end

        def absolute_top_right
          [absolute_right, absolute_top]
        end

        def absolute_bottom_left
          [absolute_left, absolute_bottom]
        end

        def absolute_bottom_right
          [absolute_right, absolute_bottom]
        end

        private

        def process_text(text)
          string = strip_zero_width_spaces(text)

          if exclude_trailing_white_space?
            string = string.rstrip

            if soft_hyphens_need_processing?(string)
              string = process_soft_hyphens(string[0..-2]) + string[-1..-1]
            end
          elsif soft_hyphens_need_processing?(string)
            string = process_soft_hyphens(string)
          end

          if direction == :rtl
            string.reverse
          else
            string
          end
        end

        def exclude_trailing_white_space?
          @format_state[:exclude_trailing_white_space]
        end

        def soft_hyphens_need_processing?(string)
          !string.empty? && normalized_soft_hyphen
        end

        def normalized_soft_hyphen
          @format_state[:normalized_soft_hyphen]
        end

        def process_soft_hyphens(string)
          if string.encoding != normalized_soft_hyphen.encoding
            string.force_encoding(normalized_soft_hyphen.encoding)
          end

          string.gsub(normalized_soft_hyphen, '')
        end

        def strip_zero_width_spaces(string)
          if string.encoding == ::Encoding::UTF_8
            string.gsub(Prawn::Text::ZWSP, '')
          else
            string
          end
        end
      end
    end
  end
end

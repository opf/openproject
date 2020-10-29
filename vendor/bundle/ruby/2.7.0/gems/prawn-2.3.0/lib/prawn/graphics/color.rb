# frozen_string_literal: true

# color.rb : Implements color handling
#
# Copyright June 2008, Gregory Brown.  All Rights Reserved.
#
# This is free software. Please see the LICENSE and COPYING files for details.

module Prawn
  module Graphics
    module Color
      # @group Stable API

      # Sets or returns the fill color.
      #
      # When called with no argument, it returns the current fill color.
      #
      # If a single argument is provided, it should be a 6 digit HTML color
      # code.
      #
      #   pdf.fill_color "f0ffc1"
      #
      # If 4 arguments are provided, the color is assumed to be a CMYK value
      # Values range from 0 - 100.
      #
      #   pdf.fill_color 0, 99, 95, 0
      #
      def fill_color(*color)
        return current_fill_color if color.empty?

        self.current_fill_color = process_color(*color)
        set_fill_color
      end

      alias fill_color= fill_color

      # Sets or returns the line stroking color.
      #
      # When called with no argument, it returns the current stroking color.
      #
      # If a single argument is provided, it should be a 6 digit HTML color
      # code.
      #
      #   pdf.stroke_color "f0ffc1"
      #
      # If 4 arguments are provided, the color is assumed to be a CMYK value
      # Values range from 0 - 100.
      #
      #   pdf.stroke_color 0, 99, 95, 0
      #
      def stroke_color(*color)
        return current_stroke_color if color.empty?

        color = process_color(*color)
        self.current_stroke_color = color
        set_stroke_color(color)
      end

      alias stroke_color= stroke_color

      module_function

      # Converts RGB value array to hex string suitable for use with fill_color
      # and stroke_color
      #
      #   >> Prawn::Graphics::Color.rgb2hex([255,120,8])
      #   => "ff7808"
      #
      def rgb2hex(rgb)
        rgb.map { |e| format '%<value>02x', value: e }.join
      end

      # Converts hex string into RGB value array:
      #
      #  >> Prawn::Graphics::Color.hex2rgb("ff7808")
      #  => [255, 120, 8]
      #
      def hex2rgb(hex)
        r = hex[0..1]
        g = hex[2..3]
        b = hex[4..5]
        [r, g, b].map { |e| e.to_i(16) }
      end

      private

      def process_color(*color)
        case color.size
        when 1
          color[0]
        when 4
          color
        else
          raise ArgumentError, 'wrong number of arguments supplied'
        end
      end

      def color_type(color)
        case color
        when String
          if /\A\h{6}\z/.match?(color)
            :RGB
          else
            raise ArgumentError, "Unknown type of color: #{color.inspect}"
          end
        when Array
          case color.length
          when 3
            :RGB
          when 4
            :CMYK
          else
            raise ArgumentError, "Unknown type of color: #{color.inspect}"
          end
        end
      end

      def normalize_color(color)
        case color_type(color)
        when :RGB
          r, g, b = hex2rgb(color)
          [r / 255.0, g / 255.0, b / 255.0]
        when :CMYK
          c, m, y, k = *color
          [c / 100.0, m / 100.0, y / 100.0, k / 100.0]
        end
      end

      def color_to_s(color)
        PDF::Core.real_params normalize_color(color)
      end

      def color_space(color)
        case color_type(color)
        when :RGB
          :DeviceRGB
        when :CMYK
          :DeviceCMYK
        end
      end

      COLOR_SPACES = %i[DeviceRGB DeviceCMYK Pattern].freeze

      def set_color_space(type, color_space)
        # don't set the same color space again
        if current_color_space(type) == color_space &&
            !state.page.in_stamp_stream?
          return
        end

        set_current_color_space(color_space, type)

        unless COLOR_SPACES.include?(color_space)
          raise ArgumentError, "unknown color space: '#{color_space}'"
        end

        operator = case type
                   when :fill
                     'cs'
                   when :stroke
                     'CS'
                   else
                     raise ArgumentError, "unknown type '#{type}'"
                   end

        renderer.add_content "/#{color_space} #{operator}"
      end

      def set_color(type, color, options = {})
        operator = case type
                   when :fill
                     'scn'
                   when :stroke
                     'SCN'
                   else
                     raise ArgumentError, "unknown type '#{type}'"
                   end

        if options[:pattern]
          set_color_space type, :Pattern
          renderer.add_content "/#{color} #{operator}"
        else
          set_color_space type, color_space(color)
          color = color_to_s(color)
          write_color(color, operator)
        end
      end

      def set_fill_color(color = nil)
        set_color :fill, color || current_fill_color
      end

      def set_stroke_color(color = nil)
        set_color :stroke, color || current_stroke_color
      end

      def update_colors
        set_fill_color
        set_stroke_color
      end

      def current_color_space(type)
        graphic_state.color_space[type]
      end

      def set_current_color_space(color_space, type)
        save_graphics_state if graphic_state.nil?
        graphic_state.color_space[type] = color_space
      end

      def current_fill_color
        graphic_state.fill_color
      end

      def current_fill_color=(color)
        graphic_state.fill_color = color
      end

      def current_stroke_color
        graphic_state.stroke_color
      end

      def current_stroke_color=(color)
        graphic_state.stroke_color = color
      end

      def write_color(color, operator)
        renderer.add_content "#{color} #{operator}"
      end
    end
  end
end

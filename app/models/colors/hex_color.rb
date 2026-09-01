# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Colors
  module HexColor
    RGB_HEX_FORMAT = /\A#[0-9A-F]{6}\z/
    private_constant :RGB_HEX_FORMAT

    ##
    # Get the fill style for this color.
    # If the color is light, use a dark font.
    # Otherwise, use a white font.
    def color_styles(light_color: "#FFFFFF", dark_color: "#333333")
      { color: contrasting_font_color(light: light_color, dark: dark_color), "background-color": hexcode }
    end

    def color_styles_css
      color_styles.map { |k, v| "#{k}: #{v};" }.join(" ")
    end

    def contrasting_font_color(light: "#FFFFFF", dark: "#333333")
      bright? ? dark : light
    end

    ##
    # Returns whether the color is dark according to
    # YIQ lightness.
    def dark?
      brightness_yiq <= 100
    end

    ##
    # Returns whether the color is bright according to
    # YIQ lightness.
    def bright?
      brightness_yiq >= 150
    end

    ##
    # Returns whether the color is very bright according to
    # YIQ lightness.
    def super_bright?
      brightness_yiq >= 200
    end

    ##
    # Sum the color values of each channel
    # Same as in frontend color-contrast.functions.ts
    def brightness_yiq
      r, g, b = rgb_colors
      ((r * 299) + (g * 587) + (b * 114)) / 1000
    end

    ##
    # Relative luminance on a 0..1 scale, using Rec. 709 luma coefficients.
    # Consumed by the highlighting stylesheet to decide contrasting text.
    def perceived_lightness
      r, g, b = rgb_colors
      (((r * 0.2126) + (g * 0.7152) + (b * 0.0722)) / 255).round(4)
    end

    ##
    # Splits the hexcode into rgb color array
    def rgb_colors
      hexcode
        .delete_prefix("#") # Remove leading #
        .ljust(6, "0") # Pad to at least 6 chars
        .scan(/../) # Pair hex chars
        .first(3)
        .map(&:hex) # to int
    end

    def rgb_modify(&)
      rgb_colors
        .map(&)
        .map(&:round)
        .map { |val| [val, 255].min }
    end

    ##
    # Darken this color by the given decimal amount
    def darken(amount)
      blend 0, 1 - amount
    end

    ##
    # Lighten this color by the given decimal amount
    def lighten(amount)
      blend 255, 1 - amount
    end

    ##
    # Blend the color with the same mix_value for all channels
    # and the given opacity
    def blend(mix_value, opacity)
      r, g, b = rgb_modify { |channel| (channel * opacity) + (mix_value * (1 - opacity)) }
      "#%<r>02x%<g>02x%<b>02x" % { r:, g:, b: }
    end

    class Normalizer
      def self.call(...)
        new.call(...)
      end

      def call(hex)
        hex = hex.strip.delete_prefix("#")
        case hex
        when /\A[0-9a-fA-F]{3}\z/ # short form: #abc
          "##{hex.chars.map { |c| c * 2 }.join.upcase}"
        when /\A[0-9a-fA-F]{6}\z/ # long form: #aabbcc
          "##{hex.upcase}"
        else # do nothing
          hex
        end
      end
    end
  end
end

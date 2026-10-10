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

module Pwa
  # Derives the offline page's colours from the instance header colour so that
  # text stays readable (WCAG AA) on any branding.
  class OfflinePalette
    Scheme = Data.define(:background, :ink, :divider, :button_background, :button_foreground, :button_hover,
                         :logo_tile, :logo_ink) do
      def white_logo? = logo_ink == WHITE
    end

    WHITE = "#ffffff"
    DARK_INK = "#1f2328"
    DARK_CANVAS = "#0d1117"
    TEXT_CONTRAST = 4.5
    BUTTON_CONTRAST = 3.0
    DARK_HEADER_MIX = 0.8
    INVERTED_HOVER_MIX = 0.9

    # Primer's primary button rest and hover colours per scheme.
    PRIMARY_BUTTON = {
      light: { rest: "#1f883d", hover: "#1c8139" },
      dark: { rest: "#238636", hover: "#29903b" }
    }.freeze

    class << self
      def contrast(color_a, color_b)
        lighter, darker = [luminance(color_a), luminance(color_b)].sort.reverse
        (lighter + 0.05) / (darker + 0.05)
      end

      def luminance(color)
        r, g, b = rgb(color).map { linearize(it) }
        (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
      end

      def rgb(color)
        hex = color.delete_prefix("#")
        hex = hex.chars.map { it * 2 }.join if hex.length == 3
        hex.scan(/../).map { it.to_i(16) }
      end

      def mix(color_a, color_b, weight)
        channels = rgb(color_a).zip(rgb(color_b)).map { |a, b| ((a * weight) + (b * (1 - weight))).round }
        "##{channels.map { it.to_s(16).rjust(2, '0') }.join}"
      end

      private

      def linearize(channel)
        value = channel / 255.0
        value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
      end
    end

    def initialize(header_color)
      @header = self.class.mix(header_color, header_color, 1)
    end

    def light = @light ||= build(:light, @header, nil)

    def dark
      @dark ||=
        if self.class.luminance(@header) > 0.5
          build(:dark, DARK_CANVAS, @header)
        else
          build(:dark, self.class.mix(@header, DARK_CANVAS, DARK_HEADER_MIX), nil)
        end
    end

    private

    def build(mode, background, logo_tile)
      ink = ink_for(background)
      button_background, button_foreground, button_hover = button_colours(mode, background, ink)

      Scheme.new(background:, ink:, divider: translucent(ink, 0.3),
                 button_background:, button_foreground:, button_hover:,
                 logo_tile:, logo_ink: logo_tile ? ink_for(logo_tile) : ink)
    end

    def ink_for(background)
      self.class.contrast(WHITE, background) >= TEXT_CONTRAST ? WHITE : DARK_INK
    end

    def button_colours(mode, background, ink)
      primary = PRIMARY_BUTTON.fetch(mode)

      if self.class.contrast(primary[:rest], background) < BUTTON_CONTRAST
        [ink, background, self.class.mix(ink, background, INVERTED_HOVER_MIX)]
      else
        [primary[:rest], WHITE, primary[:hover]]
      end
    end

    def translucent(color, alpha)
      "rgba(#{self.class.rgb(color).join(', ')}, #{alpha})"
    end
  end
end

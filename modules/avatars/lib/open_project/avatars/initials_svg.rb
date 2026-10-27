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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Avatars
    # Renders a user's fallback avatar (initials on a colored background) as an SVG,
    # mirroring what the frontend used to compute in principal-renderer.service.ts so the
    # server can serve a real image instead of letting that endpoint 404.
    module InitialsSvg
      module_function

      def render(principal)
        build_svg(color_for(principal), text_for(principal))
      end

      def text_for(principal)
        if AvatarManager.avatar_type_for(principal) == "initials" && principal.avatar_text.present?
          principal.avatar_text
        else
          initials_for(principal.name)
        end
      end

      def color_for(user)
        custom_color = user.respond_to?(:avatar_color) ? user.avatar_color : nil
        return custom_color if custom_color.present?

        "hsl(#{hue_for("#{user.id}#{user.name}")}, 50%, 30%)"
      end

      def initials_for(name)
        characters = name.to_s.grapheme_clusters
        return "" if characters.empty?

        first = characters.first.upcase
        last_space = characters.rindex(" ")
        return first if last_space.nil?

        last = characters[last_space + 1]
        last ? "#{first}#{last.upcase}" : first
      end

      def hue_for(value)
        hash = value.each_char.reduce(0) { |acc, char| char.ord + ((acc << 5) - acc) }
        hash % 360
      end

      def build_svg(color, initials)
        <<~SVG
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
            <rect width="64" height="64" fill="#{escape(color)}" />
            <text x="32" y="34" text-anchor="middle" dominant-baseline="middle" font-family="system-ui, -apple-system, sans-serif" font-size="28" text-rendering="geometricPrecision" fill="#{text_color_for(color)}">#{escape(initials)}</text>
          </svg>
        SVG
      end

      def text_color_for(color)
        return "#ffffff" unless color.start_with?("#")

        ::Color.new(hexcode: color).contrasting_font_color(light: "#ffffff", dark: "#1f2328")
      end

      def escape(value)
        CGI.escapeHTML(value.to_s)
      end
    end
  end
end

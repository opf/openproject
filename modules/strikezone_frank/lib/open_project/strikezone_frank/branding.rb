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

module OpenProject
  module StrikezoneFrank
    # Upgrade-safe Strikezone branding for WP #55.
    #
    # OpenProject already exposes Administration > Settings > General for
    # app_title / software_name, and Administration > Design (EE) for theme
    # colours. This helper only replaces the stock "OpenProject" defaults so a
    # fresh install (or reset) becomes Strikezone without overwriting an
    # admin-chosen custom title later.
    #
    # Community Edition never applies DesignColor CSS (`apply_custom_styles?`
    # is EE-gated). Theme tokens are therefore also injected by the plugin
    # view hook; derived hover/focus colours reuse OpenProject's HexColor
    # helpers so they match `_inline_css.erb`.
    module Branding
      TITLE = "Strikezone"
      THEME_NAME = "Strikezone"
      DEFAULT_OPENPROJECT_TITLE = "OpenProject"
      FONT_FAMILY = '"Baloo Bhaina 2", -apple-system, BlinkMacSystemFont, "Segoe UI", "Noto Sans", Helvetica, Arial, sans-serif'

      # Brandbook / Colors.pdf → OpenProject Design tokens.
      COLORS = {
        "primary-button-color" => "#DF5301", # Primary 700
        "accent-color" => "#ED6718", # Primary 600 / brand orange
        "header-bg-color" => "#101010",
        "main-menu-bg-color" => "#FFFFFF",
        "main-menu-bg-selected-background" => "#FFF3EC" # Primary 50
      }.freeze

      FONT_FILES = {
        400 => "strikezone_frank/baloo-bhaina-2-latin-400.woff2",
        500 => "strikezone_frank/baloo-bhaina-2-latin-500.woff2",
        600 => "strikezone_frank/baloo-bhaina-2-latin-600.woff2",
        700 => "strikezone_frank/baloo-bhaina-2-latin-700.woff2"
      }.freeze

      module_function

      def apply!
        return unless settings_table_ready?

        apply_setting(:app_title)
        apply_setting(:software_name)
      rescue StandardError => e
        Rails.logger.warn("[strikezone_frank] branding apply skipped: #{e.class}: #{e.message}")
      end

      def apply_setting(key)
        current = Setting.send(key)
        return if current.present? && current != DEFAULT_OPENPROJECT_TITLE

        Setting.send(:"#{key}=", TITLE)
      end

      def settings_table_ready?
        ActiveRecord::Base.connection.data_source_exists?("settings")
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
        false
      end

      def color_theme
        {
          theme: THEME_NAME,
          colors: COLORS,
          logo: "strikezone_frank/logo-white.svg"
        }
      end

      # EE Design CSS (`_inline_css.erb`) already computed derived tokens.
      # Skip plugin colour injection so an admin-chosen theme still wins.
      def inject_theme_tokens?
        return true unless design_colors_table_ready?
        return true unless EnterpriseToken.allows_to?(:define_custom_style)

        DesignColor.overwritten.empty?
      rescue StandardError
        true
      end

      def theme_css_variables
        primary = Swatch.new(COLORS.fetch("primary-button-color"))
        accent = Swatch.new(COLORS.fetch("accent-color"))
        header = Swatch.new(COLORS.fetch("header-bg-color"))
        menu = Swatch.new(COLORS.fetch("main-menu-bg-color"))

        COLORS.merge(
          "primary-button-color--major1" => primary.darken(0.18),
          "primary-button-color--minor1" => primary.lighten(0.8),
          "primary-button-color--minor2" => primary.lighten(0.6),
          "primary-button-color--dark-mode" => primary.lighten(0.4),
          "font-color-on-primary" => primary.contrasting_font_color,
          "accent-color--major1" => accent.darken(0.2),
          "accent-color--major2" => accent.darken(0.4),
          "accent-color--minor1" => accent.lighten(0.8),
          "accent-color--minor2" => accent.lighten(0.6),
          "accent-color--dark-mode" => accent.lighten(0.4),
          "header-item-font-color" => header.contrasting_font_color,
          "header-border-bottom-color" => COLORS.fetch("header-bg-color"),
          "main-menu-font-color" => menu.contrasting_font_color(dark: "#1F1F1F"),
          "body-font-family" => FONT_FAMILY,
          "body-font-color" => "#1F1F1F",
          "body-font-size" => "1rem"
        )
      end

      def design_colors_table_ready?
        ActiveRecord::Base.connection.data_source_exists?("design_colors")
      rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
        false
      end

      # Lightweight HexColor wrapper so plugin CSS can reuse core darken/lighten.
      class Swatch
        include Colors::HexColor

        attr_reader :hexcode

        def initialize(hexcode)
          @hexcode = hexcode
        end
      end
    end
  end
end

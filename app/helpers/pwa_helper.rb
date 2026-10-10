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

module PwaHelper
  SHORT_NAME_MAX_LENGTH = 12
  SHELL_CACHE_PREFIX = "openproject-shell-"
  SHELL_ENTRY_FILES = %w[polyfills.js main.js styles.css].freeze
  OFFLINE_WORDMARK = "logo_openproject_white_big.png"
  OFFLINE_MARK = "icon_logo.svg"
  SHELL_ICONS = %w[pwa/icon-192.png pwa/icon-512.png pwa/icon-1024.png pwa/icon.svg].freeze

  def pwa_short_name(title = Setting.app_title)
    [title, title.split.first].compact.find { it.length <= SHORT_NAME_MAX_LENGTH }
  end

  def pwa_shell_cache_prefix = SHELL_CACHE_PREFIX

  # Only same-origin paths: the worker caches nothing served from an asset host.
  def pwa_shell_precache
    return [] if FrontendAssetHelper.assets_proxied?

    same_origin_paths(SHELL_ENTRY_FILES.map { raw_variable_asset_path(it) } + SHELL_ICONS.map { image_path(it) })
  end

  def pwa_offline_custom_logo_url
    return unless apply_custom_styles?

    custom_logo_urls(CustomStyle.current).dig(:desktop, :light)
  end

  def pwa_offline_precache
    custom_logo = pwa_offline_custom_logo_url
    logos = custom_logo ? [custom_logo] : [image_path(OFFLINE_WORDMARK), image_path(OFFLINE_MARK)]

    same_origin_paths([pwa_offline_path, *logos])
  end

  def pwa_offline_palette
    Pwa::OfflinePalette.new(header_bg_color)
  end

  def pwa_offline_css_variables(scheme, border)
    {
      bg: scheme.background,
      ink: scheme.ink,
      divider: scheme.divider,
      "button-bg": scheme.button_background,
      "button-fg": scheme.button_foreground,
      "button-hover-bg": scheme.button_hover,
      "button-border": border,
      "tile-bg": scheme.logo_tile || "transparent",
      "tile-padding": scheme.logo_tile ? "16px" : "0",
      "logo-ink": scheme.logo_ink,
      "wordmark-display": scheme.white_logo? ? "block" : "none",
      "mark-display": scheme.white_logo? ? "none" : "flex"
    }.map { |name, value| "--offline-#{name}: #{value};" }.join(" ")
  end

  def pwa_shell_cache_name
    version = [*pwa_shell_precache, *pwa_offline_precache, Setting.app_title,
               CustomStyle.current&.digest, OpenProject::VERSION.to_s].join
    "#{SHELL_CACHE_PREFIX}#{Digest::SHA256.hexdigest(version).first(16)}"
  end

  private

  def same_origin_paths(urls)
    urls.select { it.start_with?("/") && !it.start_with?("//") }
  end
end

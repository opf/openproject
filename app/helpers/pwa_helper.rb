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

module PwaHelper
  OFFLINE_WORDMARK = Rails.root.join("app/assets/images/logo_openproject_white_big.png")

  def pwa_offline_wordmark_data_uri
    "data:image/png;base64,#{Base64.strict_encode64(OFFLINE_WORDMARK.binread)}"
  end

  def pwa_theme_color_tags
    pref = User.current.pref

    if pref.sync_with_os_theme?
      safe_join(sync_with_os_theme_color_tags(force_light_contrast: pref.force_light_theme_contrast?), "\n")
    else
      theme_color_tag(header_bg_color(color_mode: pref.dark_color_mode? ? :dark : :light,
                                      high_contrast: pref.increase_theme_contrast?))
    end
  end

  private

  def sync_with_os_theme_color_tags(force_light_contrast:)
    light = "(prefers-color-scheme: light)"
    dark_tag = theme_color_tag(header_bg_color(color_mode: :dark), media: "(prefers-color-scheme: dark)")

    if force_light_contrast
      [theme_color_tag(header_bg_color(color_mode: :light, high_contrast: true), media: light), dark_tag]
    else
      [
        theme_color_tag(header_bg_color(color_mode: :light, high_contrast: true), media: "#{light} and (prefers-contrast: more)"),
        theme_color_tag(header_bg_color(color_mode: :light), media: light),
        dark_tag
      ]
    end
  end

  def theme_color_tag(color, media: nil)
    tag.meta(name: "theme-color", content: color, media:)
  end
end

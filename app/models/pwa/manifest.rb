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

module Pwa
  class Manifest
    SHORT_NAME_MAX_LENGTH = 12
    BACKGROUND_COLOR = "#ffffff"
    ICON_SIZES = [192, 512].freeze

    def initialize(helpers)
      @helpers = helpers
    end

    def as_json(*)
      {
        name: Setting.app_title,
        short_name:,
        id: root,
        start_url: root,
        scope: root,
        display: "standalone",
        prefer_related_applications: true,
        related_applications: [
          { platform: "play",
            id: "org.openproject.app",
            url: OpenProject::Static::Links.url_for(:mobile_app_play_store) }
        ],
        theme_color: @helpers.header_bg_color,
        background_color: BACKGROUND_COLOR,
        icons:
      }.compact
    end

    private

    def root
      @helpers.root_path
    end

    def short_name
      title = Setting.app_title.presence
      title if title && title.length <= SHORT_NAME_MAX_LENGTH
    end

    def icons
      ICON_SIZES.map { icon("icon-#{it}.png", it) } + [icon("icon-512-maskable.png", 512, purpose: "maskable")]
    end

    def icon(file, size, **extra)
      { src: @helpers.image_path("pwa/#{file}"), sizes: "#{size}x#{size}", type: "image/png", **extra }
    end
  end
end

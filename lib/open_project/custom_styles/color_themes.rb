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

module OpenProject::CustomStyles
  module ColorThemes
    module_function

    OpenProject::CustomStyles::ColorThemes::DEFAULT_THEME_NAME = "OpenProject (default)".freeze

    DEPRECATED_ALTERNATIVE_COLOR = "#35C53F".freeze
    DEPRECATED_PRIMARY_COLOR = "#1A67A3".freeze
    DEPRECATED_BIM_ALTERNATIVE_COLOR = "#349939".freeze
    DEPRECATED_PRIMARY_DARK_COLOR = "#175A8E".freeze
    DEPRECATED_LINK_COLOR = "#155282".freeze
    PRIMER_PRIMARY_BUTTON_COLOR = "#1F883D".freeze
    ACCENT_COLOR = "#1A67A3".freeze

    THEMES = [
      {
        theme: OpenProject::CustomStyles::ColorThemes::DEFAULT_THEME_NAME,
        colors: {
          "primary-button-color" => PRIMER_PRIMARY_BUTTON_COLOR,
          "accent-color" => ACCENT_COLOR,
          "header-bg-color" => "#1A67A3",
          "header-item-bg-hover-color" => "#175A8E",
          "main-menu-bg-color" => "#333739",
          "main-menu-bg-selected-background" => "#175A8E",
          "main-menu-bg-hover-background" => "#124E7C",
        }
      },
      {
        theme: "OpenProject Gray",
        colors: {
          "primary-button-color" => PRIMER_PRIMARY_BUTTON_COLOR,
          "accent-color" => ACCENT_COLOR,
          "header-bg-color" => "#FAFAFA",
          "header-item-bg-hover-color" => "#E1E1E1",
          "main-menu-bg-color" => "#ECECEC",
          "main-menu-bg-selected-background" => "#A9A9A9",
          "main-menu-bg-hover-background" => "#FFFFFF",
        },
        logo: "logo_openproject.png"
      },
      {
        theme: "OpenProject Navy Blue",
        colors: {
          "primary-button-color" => PRIMER_PRIMARY_BUTTON_COLOR,
          "accent-color" => ACCENT_COLOR,
          "header-bg-color" => "#05002C",
          "header-item-bg-hover-color" => "#163473",
          "main-menu-bg-color" => "#0E2045",
          "main-menu-bg-selected-background" => "#3270DB",
          "main-menu-bg-hover-background" => "#163473",
        }
      }
    ].freeze

    def themes
      THEMES
    end
  end
end

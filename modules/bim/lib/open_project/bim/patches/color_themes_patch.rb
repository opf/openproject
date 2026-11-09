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

require "open_project/custom_styles/design"

OpenProject::CustomStyles::ColorThemes::BIM_THEME_NAME = "OpenProject BIM".freeze

module OpenProject::Bim
  module Patches
    module ColorThemesPatch
      def self.included(base)
        class << base
          prepend ClassMethods
        end
      end

      module ClassMethods
        def themes
          if OpenProject::Configuration.bim?
            super + [bim_theme]
          else
            super
          end
        end

        def bim_theme
          {
            theme: OpenProject::CustomStyles::ColorThemes::BIM_THEME_NAME,
            colors: {
              "primary-button-color" => OpenProject::CustomStyles::ColorThemes::PRIMER_PRIMARY_BUTTON_COLOR,
              "header-bg-color" => "#05002C",
              "accent-color" => "#275BB5",
              "main-menu-bg-color" => "#0E2045",
              "main-menu-bg-selected-background" => "#3270DB",
              # TODO 'new-feature-teaser-image' => '#{image-url("bim/new_feature_teaser.jpg")}'
            },
            logo: "bim/logo_openproject_bim_big.png"
          }
        end
      end
    end
  end
end

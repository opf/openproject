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
  module Design
    module_function

    ##
    # Returns the name of the color scheme.
    # To be overridden by a plugin
    def name
      "OpenProject Theme"
    end

    def identifier
      :core_design
    end

    def overridden?
      identifier == :core_design
    end

    ##
    # Path to favicon
    def favicon_asset_path
      if OpenProject::Configuration.development_highlight_enabled?
        "development/favicon.ico".freeze
      else
        "favicon.ico".freeze
      end
    end

    ##
    # Path to apple touch icon
    def apple_touch_icon_asset_path
      if OpenProject::Configuration.development_highlight_enabled?
        "development/apple-touch-icon-120x120.png".freeze
      else
        "apple-touch-icon-120x120.png".freeze
      end
    end

    ##
    # Returns the keys of variables that are customizable through the design
    def customizable_variables
      %w( primary-button-color
          accent-color
          header-bg-color
          header-item-bg-hover-color
          header-item-font-color
          header-item-font-hover-color
          header-border-bottom-color
          main-menu-bg-color
          main-menu-bg-selected-background
          main-menu-bg-hover-background
          main-menu-font-color
          main-menu-selected-font-color
          main-menu-hover-font-color
          main-menu-border-color )
    end
  end
end

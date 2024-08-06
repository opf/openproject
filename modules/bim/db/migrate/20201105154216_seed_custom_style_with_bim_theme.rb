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

# This migration cleans up messed up themes. Sometimes in the past
# the BIM theme was not set where it should have been set.
class SeedCustomStyleWithBimTheme < ActiveRecord::Migration[6.0]
  def up
    # When
    #   migrating BIM instances
    #     that did not have any custom styles OR
    #       that do not have any design colors set and no custom logo/touch-icon/favicon
    #       (this basically means that no theme actually got applied)
    # then
    #   add a custom style with the BIM theme set. This will write the theme's colors
    #   as DesignColor entries to the DB which is necessary for the theme to actually
    #   have an effect.
    if OpenProject::Configuration.bim? &&
       (CustomStyle.current.nil? ||
           (DesignColor.count == 0 &&
               CustomStyle.current.favicon.nil? &&
               CustomStyle.current.logo.nil? &&
               CustomStyle.current.touch_icon.nil?))
      seed_bim_theme
    end
  end

  def down
    # nop
  end

  private

  def seed_bim_theme
    CustomStyle.transaction do
      set_custom_style
      set_design_colors
    end
  end

  def set_design_colors
    # There should not be any DesignColors present. However, we want to make sure.
    DesignColor.delete_all

    theme[:colors].each do |param_variable, param_hexcode|
      DesignColor.create variable: param_variable, hexcode: param_hexcode
    end
  end

  def set_custom_style
    custom_style = CustomStyle.current || CustomStyle.create!
    custom_style.attributes = { theme: theme[:theme], theme_logo: theme[:logo] }
    custom_style.save!
    custom_style
  end

  def theme
    {
      theme: "OpenProject BIM",
      colors: {
        "primary-color" => "#3270DB",
        "primary-color-dark" => "#163473",
        "alternative-color" => "#349939",
        "header-bg-color" => "#05002C",
        "header-item-bg-hover-color" => "#163473",
        "content-link-color" => "#275BB5",
        "main-menu-bg-color" => "#0E2045",
        "main-menu-bg-selected-background" => "#3270DB",
        "main-menu-bg-hover-background" => "#163473"
      },
      logo: "bim/logo_openproject_bim_big.png"
    }
  end
end

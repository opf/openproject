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

class MigrateLightBackgroundThemes < ActiveRecord::Migration[5.1]
  NEW_COLOR_VARIABLES = %w( main-menu-font-color
                            main-menu-bg-selected-background
                            main-menu-selected-font-color
                            main-menu-bg-hover-background
                            main-menu-hover-font-color
                            main-menu-border-color ).freeze
  def down
    # This migration is not revertible.
  end

  def up
    # This migration is "nice to have". There is no harm if it does not get applied.
    return unless apply?

    # Main menu was set to white
    if DesignColor.find_by(variable: "main-menu-bg-color")&.hexcode == "#FFFFFF"
      set_old_default_menu_colors
    end

    # Header is white and main menu was default light grey
    if DesignColor.find_by(variable: "header-bg-color")&.hexcode == "#FFFFFF" &&
       DesignColor.find_by(variable: "main-menu-bg-color").nil?
      set_variable("main-menu-bg-color", "#F8F8F8")
      set_old_default_menu_colors
    end
  end

  def set_old_default_menu_colors
    content_link_color = DesignColor.find_by(variable: "content-link-color")&.hexcode ||
                         DesignColor.find_by(variable: "primary-color-dark")&.hexcode ||
                         "#175A8E"

    set_variable("main-menu-font-color",             "#333333")
    set_variable("main-menu-bg-selected-background", "#E9E9E9")
    set_variable("main-menu-selected-font-color",    content_link_color)
    set_variable("main-menu-bg-hover-background",    "#F0F0F0")
    set_variable("main-menu-hover-font-color",       "#333333")
    set_variable("main-menu-border-color",           "#E7E7E7")
  end

  def set_variable(variable_name, hexcode)
    DesignColor.create(variable: variable_name, hexcode:)
  end

  def apply?
    # Future safety: Check that all necessary variables are still in use.
    %w( content-link-color
        header-bg-color
        header-border-bottom-color
        main-menu-bg-color
        main-menu-font-color
        main-menu-bg-selected-background
        main-menu-selected-font-color
        main-menu-bg-hover-background
        main-menu-hover-font-color
        main-menu-border-color ).each do |variable_name|
      return false unless OpenProject::CustomStyles::Design.customizable_variables.include? variable_name
    end

    # Never ever overwrite variables that were already set.
    # The existence of one variable is sufficient to better abort this migration.
    false if DesignColor.where(variable: NEW_COLOR_VARIABLES).any?

    true
  end
end

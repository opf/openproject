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

module Design
  class UpdateDesignService
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      CustomStyle.transaction do
        set_logo
        set_colors
        set_theme

        custom_style.save!

        ServiceResult.success result: custom_style
      end
    rescue StandardError => e
      ServiceResult.failure message: e.message
    end

    private

    def set_logo
      custom_style.theme_logo = params[:logo].presence
    end

    def set_colors
      return unless params[:colors]

      # reset all colors if a new theme is set
      if params[:theme].present?
        DesignColor.delete_all
      end


      params[:colors].each do |param_variable, param_hexcode|
        # design_font_color = DesignColor.find_by(variable: "main-menu-font-color")
        # contrast_color = get_contrast_color('#eeeeee')
        #
        # design_font_color.hexcode = contrast_color
        # design_font_color.save

        set_font_color(param_variable, param_hexcode);
        if design_color = DesignColor.find_by(variable: param_variable)


          if param_hexcode.blank?
            design_color.destroy
          elsif design_color.hexcode != param_hexcode
            design_color.hexcode = param_hexcode
            design_color.save
          end
        else
          # create that design_color
          design_color = DesignColor.new variable: param_variable, hexcode: param_hexcode
          design_color.save
        end
      end
    end

    def set_theme
      custom_style.theme = params[:theme].presence
    end

    def custom_style
      @custom_style ||= CustomStyle.current || CustomStyle.create!
    end

    def set_font_color(color_variable, color_hexcode)
      if color_variable === "header-bg-color"
        create_update_color("header-item-font-color", color_hexcode)
      elsif color_variable === "header-item-bg-hover-color"
        create_update_color("header-item-font-hover-color", color_hexcode)
      elsif color_variable === "main-menu-bg-color"
        create_update_color("main-menu-font-color", color_hexcode)
      elsif color_variable === "main-menu-bg-selected-background"
        create_update_color("main-menu-selected-font-color", color_hexcode)
      elsif color_variable === "main-menu-bg-hover-background"
        create_update_color("main-menu-hover-font-color", color_hexcode)
      end
    end
    def create_update_color(color_variable, color_hexcode)
      design_font_color = DesignColor.find_by(variable: color_variable)
      contrast_color = get_contrast_color(color_hexcode)

      design_font_color.hexcode = contrast_color
      design_font_color.save
    end
    def get_contrast_color(hex)
      # Convert hex to RGB
      color = ColorConversion::Color.new(hex)
      rgb = color.rgb

      # Calculate luminance
      luminance = calculate_luminance(rgb[:r], rgb[:g], rgb[:b])

      # Return black or white depending on luminance
      luminance > 0.5 ? '#333333' : '#FFFFFF'
    end

    def calculate_luminance(r, g, b)
      # Normalize RGB values to the range [0, 1]
      r_norm = r / 255.0
      g_norm = g / 255.0
      b_norm = b / 255.0

      # Calculate luminance using the formula
      0.2126 * r_norm + 0.7152 * g_norm + 0.0722 * b_norm
    end
  end
end

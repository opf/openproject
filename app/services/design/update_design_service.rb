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
  end
end

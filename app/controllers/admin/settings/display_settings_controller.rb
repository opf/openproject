#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

module Admin::Settings
  class DisplaySettingsController < ::Admin::SettingsController
    menu_item :settings_display

    before_action :validate_start_of_week_year, only: :update

    def show
      @options = {}
      @options[:user_format] = User::USER_FORMATS_STRUCTURE.keys.map { |f| [User.current.name(f), f.to_s] }

      respond_to :html
    end

    def default_breadcrumb
      t(:label_display)
    end

    private

    def validate_start_of_week_year
      start_of_week = params[:settings][:start_of_week]
      start_of_year = params[:settings][:first_week_of_year]

      if start_of_week.present? ^ start_of_year.present?
        flash[:error] = I18n.t(
          'settings.display.first_date_of_week_and_year_set',
          first_week_setting_name: I18n.t(:setting_first_week_of_year),
          day_of_week_setting_name: I18n.t(:setting_start_of_week)
        )
        redirect_to action: :show
      end
    end
  end
end

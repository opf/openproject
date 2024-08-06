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

module Admin::Settings
  class WorkingDaysAndHoursSettingsController < ::Admin::SettingsController
    menu_item :working_days_and_hours

    def failure_callback(call)
      @modified_non_working_days = modified_non_working_days_for(call.result)
      flash[:error] = call.message || I18n.t(:notice_internal_server_error)
      render action: "show"
    end

    protected

    def settings_params
      super.tap do |settings|
        settings[:working_days] = working_days_params(settings)
        settings[:non_working_days] = non_working_days_params
      end
    end

    def update_service
      ::Settings::WorkingDaysAndHoursUpdateService
    end

    private

    def working_days_params(settings)
      settings[:working_days] ? settings[:working_days].compact_blank.map(&:to_i).uniq : []
    end

    def non_working_days_params
      non_working_days = params[:settings].to_unsafe_hash[:non_working_days_attributes] || {}
      non_working_days.to_h.values
    end

    def modified_non_working_days_for(result)
      return if result.nil?

      result.map do |record|
        json_attributes = record.as_json(only: %i[id name date])
        json_attributes["_destroy"] = true if record.marked_for_destruction?
        json_attributes
      end
    end
  end
end

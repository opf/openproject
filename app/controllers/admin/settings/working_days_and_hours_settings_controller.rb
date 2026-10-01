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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin::Settings
  class WorkingDaysAndHoursSettingsController < ::Admin::SettingsController
    include OpTurbo::ComponentStream

    menu_item :working_days_and_hours

    def confirm_changes
      return update unless working_days_changed? || non_working_days_changed?

      removed_days = non_working_days_params
        .select { |nwd| nwd["_destroy"].present? }
        .filter_map { |nwd| removed_non_working_day_date(nwd) }

      component = Admin::Settings::WorkingDays::ConfirmDialogComponent.new(
        form_values: params.expect(settings: {}).to_h,
        removed_non_working_days: removed_days
      )

      respond_with_dialog(component)
    end

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

    def working_days_changed?
      working_days_params(params.expect(settings: {})) != Setting.working_days.map(&:to_i)
    end

    def non_working_days_changed?
      non_working_days_params.any?
    end

    def working_days_params(settings)
      settings[:working_days] ? settings[:working_days].compact_blank.map(&:to_i).uniq : []
    end

    def non_working_days_params
      non_working_days = params.expect(settings: {})[:non_working_days_attributes] || {}
      non_working_days.to_h.values
    end

    def removed_non_working_day_date(non_working_day_params)
      date = NonWorkingDay.find_by(id: non_working_day_params["id"])&.date || non_working_day_params["date"]

      I18n.l(date.to_date, format: :long)
    rescue Date::Error, NoMethodError
      nil
    end

    def modified_non_working_days_for(result)
      records = non_working_day_records_from(result)
      return if records.blank?

      records.map do |record|
        json_attributes = record.as_json(only: %i[id name date])
        json_attributes["date"] = json_attributes["date"].iso8601 if json_attributes["date"].respond_to?(:iso8601)
        json_attributes["_destroy"] = true if record.marked_for_destruction?
        json_attributes
      end
    end

    # If we fails to save the new NonWorkingDay records, we will return the state
    # as the user submitted it.
    # That allows them to correct the mistake or wait for the unprocessed job to finish.
    def non_working_day_records_from(result)
      if result.is_a?(Enumerable) && result.all?(NonWorkingDay)
        result.to_a
      else
        non_working_day_records_from_params
      end
    end

    def non_working_day_records_from_params
      non_working_days_params.filter_map do |attrs|
        attrs = attrs.to_h.with_indifferent_access
        record = find_or_build_non_working_day(attrs)
        next unless record

        record.assign_attributes(attrs.slice(:name, :date))
        record.mark_for_destruction if attrs[:_destroy].present?
        record
      end
    end

    def find_or_build_non_working_day(attrs)
      if attrs[:id].present?
        NonWorkingDay.find_by(id: attrs[:id])
      else
        NonWorkingDay.new
      end
    end
  end
end

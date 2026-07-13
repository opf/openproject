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

class My::Notifications::DateAlertsForm < ApplicationForm
  START_DUE_TIMES = %w[0 1 3 7].freeze
  OVERDUE_TIMES = %w[1 3 7].freeze

  def initialize(show_submit: true)
    super()
    @show_submit = show_submit
  end

  form do |f|
    f.fieldset_group(title: helpers.t("my_account.notifications.date_alerts.title"),
                     description: helpers.t("my_account.notifications.date_alerts.description"),
                     mt: 3) do |fg|
      %i[start_date due_date].each do |field|
        active = model.send(:"#{field}_active")

        fg.check_box(
          name: :"#{field}_active",
          label: helpers.t("my_account.notifications.date_alerts.#{field}"),
          id: "op-notification-type-#{field}-date-active--#{SecureRandom.uuid}}",
          data: {
            show_when_checked_target: "cause",
            target_name: field.to_s,
            test_selector: "global-notification-type-op-settings-#{field}-date-active"
          }
        ) do |cb|
          cb.nested_form(
            classes: [{ "d-none" => !active }],
            data: {
              show_when_checked_target: "effect",
              target_name: field.to_s,
              show_when: "checked"
            }
          ) do |builder|
            TimeSelectForm.new(builder, field:, times: START_DUE_TIMES)
          end
        end
      end

      active_overdue = model.overdue_active

      fg.check_box(
        name: :overdue_active,
        label: helpers.t("my_account.notifications.date_alerts.overdue"),
        id: "op-notification-type-overdue-date-active--#{SecureRandom.uuid}}",
        data: {
          show_when_checked_target: "cause",
          target_name: "overdue",
          test_selector: "global-notification-type-op-settings-overdue-date-active"
        }
      ) do |cb|
        cb.nested_form(
          classes: [{ "d-none" => !active_overdue }],
          data: {
            show_when_checked_target: "effect",
            target_name: "overdue",
            show_when: "checked"
          }
        ) do |builder|
          TimeSelectForm.new(builder, field: :overdue, times: OVERDUE_TIMES)
        end
      end

      if @show_submit
        fg.submit(name: :submit, label: helpers.t("my_account.notifications.date_alerts.submit_button"),
                  scheme: :default)
      end
    end
  end

  class TimeSelectForm < ApplicationForm
    def initialize(field:, times:)
      super()
      @field = field
      @times = times
    end

    form do |f|
      f.select_list(
        name: @field,
        label: helpers.t("my_account.notifications.date_alerts.#{@field}"),
        visually_hide_label: true,
        input_width: :xsmall,
        data: { test_selector: "global-notification-type-op-reminder-settings-#{@field.to_s.underscore}-alerts" }
      ) do |list|
        @times.each do |value|
          list.option(
            label: helpers.t("my_account.notifications.date_alerts.times.#{time_key(value)}"),
            value:
          )
        end
      end
    end

    private

    def time_key(value)
      case value
      when "0" then "same_day"
      when "1" then @field == :overdue ? "one_day_after" : "one_day_before"
      when "3" then @field == :overdue ? "three_days_after" : "three_days_before"
      when "7" then @field == :overdue ? "seven_days_after" : "seven_days_before"
      end
    end
  end
end

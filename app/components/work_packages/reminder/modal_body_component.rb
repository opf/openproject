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

module WorkPackages
  module Reminder
    class ModalBodyComponent < ApplicationComponent
      include ApplicationHelper
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      FORM_ID = "reminder-form"
      DEFAULT_TIME = "09:00"

      attr_reader :remindable, :reminder, :errors, :preset

      def initialize(remindable:, reminder:, errors: nil, preset: nil, remind_at_date: nil, remind_at_time: nil)
        super

        @remindable = remindable
        @reminder = reminder
        @errors = errors
        @preset = preset
        @remind_at_date = remind_at_date
        @remind_at_time = remind_at_time
      end

      class << self
        def wrapper_key
          "reminder_modal_body"
        end
      end

      def submit_path
        if @reminder.persisted?
          url_helpers.work_package_reminder_path(@remindable, @reminder)
        else
          url_helpers.work_package_reminders_path(@remindable)
        end
      end

      def submit_button_text
        if @reminder.persisted?
          I18n.t(:button_save)
        else
          I18n.t(:button_set_reminder)
        end
      end

      def cancel_button_props
        {
          scheme: :secondary,
          data: {
            controller: "primer-to-angular-modal",
            action: "click->primer-to-angular-modal#close",
            test_selector: "op-reminder-modal-close-button"
          }
        }
      end

      def remind_at_date_initial_value
        if attribute_blank?(:remind_at_time) && @remind_at_date.present?
          # If the time is not set, we return the date that was passed in
          return @remind_at_date
        end

        return time_as_date(@reminder.remind_at) if @reminder.remind_at
        return calculate_preset_date if @preset

        nil
      end

      def remind_at_time_initial_value
        if attribute_blank?(:remind_at_date) && @remind_at_time.present?
          # If the date is not set, we return the time that was passed in
          return @remind_at_time
        end

        return format_time(@reminder.remind_at, include_date: false, format: "%H:%M") if @reminder.remind_at

        DEFAULT_TIME
      end

      private

      def calculate_preset_date
        case @preset
        when "tomorrow" then time_as_date(1.day.from_now)
        when "three_days" then time_as_date(3.days.from_now)
        when "week" then time_as_date(7.days.from_now)
        when "month" then time_as_date(1.month.from_now)
        when "custom" then nil
        end
      end

      def time_as_date(time)
        format_date(time, format: "%Y-%m-%d")
      end

      def attribute_blank?(attribute)
        @errors.present? &&
          @errors.any? { |error| error.attribute == attribute && error.type == :blank }
      end
    end
  end
end

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

module Users
  module NonWorkingTimes
    class CalendarComponent < ApplicationComponent
      include OpTurbo::Streamable
      include OpPrimer::ComponentHelpers

      options non_working_times: [],
              year: Date.current.year,
              user: nil

      private

      def can_update?
        user.present? && UserNonWorkingTimes::UpdateContract.can_update?(user: User.current, target_user: user)
      end

      def can_create?
        user.present? && UserNonWorkingTimes::CreateContract.can_create?(user: User.current, target_user: user)
      end

      def wrapper_data
        data = {
          "controller" => "users--non-working-times",
          "users--non-working-times-events-value" => events_json,
          "users--non-working-times-year-value" => year,
          "users--non-working-times-locale-value" => I18n.locale,
          "users--non-working-times-start-of-week-value" => first_day_of_week,
          "users--non-working-times-working-days-value" => working_days.to_json
        }

        if can_create?
          data["users--non-working-times-new-url-value"] = new_user_non_working_time_path(user)
        end

        data
      end

      def working_days
        # Setting.working_days is mo=1, tu=2, we=3, th=4, fr=5, sa=6, su=7
        # businessHours in fullcalendar is su=0, mo=1, tu=2, we=3, th=4, fr=5, sa=6
        Setting.working_days.map { |day| day % 7 }.sort
      end

      def events_json
        (global_events + user_events).to_json
      end

      def global_events
        non_working_times
          .grep(NonWorkingDay)
          .map do |day|
            { date: day.date.iso8601, title: day.name, type: "global" }
          end
      end

      def user_events
        system_dates = non_working_times.grep(NonWorkingDay).to_set(&:date)
        non_working_times
          .grep(UserNonWorkingTime)
          .map { |nwt| user_event_for(nwt, system_dates) }
      end

      def user_event_for(nwt, system_dates)
        clipped = nwt.clip_to_year(year, system_non_working_dates: system_dates)
        {
          start: clipped.start_date.iso8601,
          end: (clipped.end_date + 1.day).iso8601,
          title: event_title(clipped),
          working_days: clipped.working_days_count,
          type: "user",
          edit_url: can_update? ? edit_user_non_working_time_path(user, nwt.id) : nil
        }.compact
      end

      def event_title(clipped)
        base = I18n.t("label_x_working_days_time_off", count: clipped.working_days_count)

        if clipped.continues_from_previous_year
          "#{base} (#{I18n.t('label_continued_from_previous_year')})"
        elsif clipped.continues_into_next_year
          "#{base} (#{I18n.t('label_continues_into_next_year')})"
        else
          base
        end
      end

      # Maps Setting.start_of_week to FullCalendar's firstDay convention.
      # Setting: nil=locale default, 1=Monday, 6=Saturday, 7=Sunday
      # FullCalendar firstDay: 0=Sunday, 1=Monday, ..., 6=Saturday
      # Nil defaults to 1 (Monday) to match Rails/OpenProject convention.
      def first_day_of_week
        (Setting.start_of_week || 1) % 7
      end
    end
  end
end

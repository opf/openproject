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
  module WorkingHours
    class CurrentScheduleComponent < ApplicationComponent
      attr_reader :working_hours, :user

      def initialize(working_hours:, user:, **)
        super(working_hours, **)
        @working_hours = working_hours
        @user = user
      end

      def editable?
        if working_hours && working_hours.valid_from == Date.current
          UserWorkingHours::UpdateContract.can_update?(user: User.current, working_hours:)
        else
          UserWorkingHours::CreateContract.can_create?(user: User.current, target_user: user)
        end
      end

      def work_days_value
        return "–" unless working_hours

        UserWorkingHours::DAYS.count { |day| working_hours.public_send(day) > 0 }.to_s
      end

      def work_days_subtitle
        return t("users.working_hours.current_schedule.not_set") unless working_hours

        working_hours.working_day_ranges
      end

      def weekly_hours_value
        return "–" unless working_hours

        format_hours(working_hours.weekly_working_hours)
      end

      def weekly_hours_subtitle
        return t("users.working_hours.current_schedule.not_set") unless working_hours

        working_hours.working_days_summary
      end

      def availability_value
        return "–" unless working_hours

        "#{working_hours.availability_factor}%"
      end

      def effective_hours_value
        return "–" unless working_hours

        format_hours(working_hours.effective_weekly_working_hours)
      end

      private

      def format_hours(hours)
        formatted = helpers.number_with_precision(hours,
                                                  precision: 2,
                                                  strip_insignificant_zeros: true,
                                                  separator: I18n.t("number.format.separator"))
        "#{formatted}h"
      end

      def create_or_edit_path
        if working_hours && working_hours.valid_from == Date.current
          edit_user_working_hour_path(user, working_hours, current: true)
        else
          new_user_working_hour_path(user, current: true)
        end
      end
    end
  end
end

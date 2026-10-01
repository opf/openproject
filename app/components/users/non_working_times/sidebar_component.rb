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
    class SidebarComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      options non_working_times: [],
              year: Date.current.year,
              user: nil

      private

      def user_non_working_times
        system_dates = non_working_times.grep(NonWorkingDay).to_set(&:date)
        non_working_times
          .grep(UserNonWorkingTime)
          .sort_by(&:start_date)
          .map { |nwt| nwt.clip_to_year(year, system_non_working_dates: system_dates) }
      end

      def global_day_count
        non_working_times.count { |d| d.is_a?(NonWorkingDay) }
      end

      def total_user_days
        user_non_working_times.sum(&:working_days_count)
      end

      def total_days
        total_user_days + global_day_count
      end

      def can_update?
        user.present? && UserNonWorkingTimes::UpdateContract.can_update?(user: User.current, target_user: user)
      end

      def can_delete?
        user.present? && UserNonWorkingTimes::DeleteContract.can_delete?(user: User.current, target_user: user)
      end

      def edit_href(clipped)
        edit_user_non_working_time_path(user, clipped.id)
      end

      def range_label(clipped)
        date_range = format_date_range(clipped.start_date, clipped.end_date)
        "#{date_range}: #{I18n.t('label_x_working_days', count: clipped.working_days_count)}"
      end

      def format_date_range(first, last)
        if first.year == last.year
          "#{I18n.l(first, format: :short)} - #{I18n.l(last, format: :short)}, #{first.year}"
        else
          "#{I18n.l(first, format: :long)} - #{I18n.l(last, format: :long)}"
        end
      end
    end
  end
end

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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

module WorkPackages
  module Shared
    class WorkingDays
      # Returns number of working days between two dates, excluding weekend days
      # and non working days.
      def duration(from_date, to_date)
        (from_date..to_date).count { working?(_1) }
      end

      private

      def working?(date)
        working_week_day?(date) && working_specific_date?(date)
      end

      def working_week_day?(date)
        working_week_days[date.wday]
      end

      def working_specific_date?(date)
        non_working_dates.exclude?(date)
      end

      def working_week_days
        return @working_week_days if defined?(@working_week_days)

        @working_week_days = [true] * 8
        WeekDay.pluck(:day, :working).each do |day, working|
          @working_week_days[day] = working
        end
        @working_week_days[0] = @working_week_days[7] # Sunday is 7 in iso or 0 in other implementations
        @working_week_days
      end

      def non_working_dates
        @non_working_dates ||= Set.new(NonWorkingDay.pluck(:date))
      end
    end
  end
end

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
      def duration(start_date, due_date)
        return no_duration unless start_date && due_date

        (start_date..due_date).count { working?(_1) }
      end

      def due_date(start_date, duration)
        return nil unless start_date && duration
        raise ArgumentError, 'duration must be strictly positive' if duration.is_a?(Integer) && duration <= 0

        due_date = start_date
        until duration <= 1 && working?(due_date)
          due_date += 1
          duration -= 1 if working?(due_date)
        end
        due_date
      end

      def add_days(date, count)
        while count > 0
          date += 1
          count -= 1 if working?(date)
        end
        while count < 0
          date -= 1
          count += 1 if working?(date)
        end
        date
      end

      def soonest_working_day(date)
        return unless date

        until working?(date)
          date += 1
        end
        date
      end

      def delta(previous:, current:)
        delta = 0
        direction = previous < current ? 1 : -1
        pos = last_pos = previous
        while pos != current
          pos += direction
          if working?(last_pos) && working?(pos)
            delta += direction
            last_pos = pos
          end
        end
        delta
      end

      def working?(date)
        working_week_day?(date) && working_specific_date?(date)
      end

      private

      def no_duration
        OpenProject::FeatureDecisions.work_packages_duration_field_active? ? nil : 1
      end

      def working_week_day?(date)
        working_week_days[date.wday]
      end

      def working_specific_date?(date)
        non_working_dates.exclude?(date)
      end

      def working_week_days
        return @working_week_days if defined?(@working_week_days)

        # WeekDay day of the week is stored as ISO, meaning Sunday is 7.
        # Ruby Date#wday value for Sunday is 0.
        # To make both work, an array of 8 elements is created
        # where array[0] = array[7] = value for Sunday
        #
        # Because the database table for WeekDay could be empty or incomplete
        # (like in tests), the initial array is built with all days considered
        # working (value is `true`)
        @working_week_days = [true] * 8
        WeekDay.pluck(:day, :working).each do |day, working|
          @working_week_days[day] = working
        end
        @working_week_days[0] = @working_week_days[7] # value for Sunday is present at index 0 AND index 7
        @working_week_days
      end

      def non_working_dates
        @non_working_dates ||= Set.new(NonWorkingDay.pluck(:date))
      end
    end
  end
end

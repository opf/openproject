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
  module Shared
    class WorkingDays
      class << self
        def clear_cache
          RequestStore.delete(:work_package_non_working_dates)
        end
      end

      # Returns number of working days between two dates, inclusive, excluding
      # weekend days and non working days.
      def duration(start_date, due_date)
        return nil unless start_date && due_date

        (start_date..due_date).count { working?(it) }
      end

      # Returns the number of working days between a predecessor date and
      # successor date, exclusive.
      def lag(predecessor_date, successor_date)
        return nil unless predecessor_date && successor_date

        duration(predecessor_date + 1.day, successor_date - 1.day)
      end

      def with_lag(date, lag)
        return nil unless date

        lag ||= 0
        if lag >= 0
          add_lag(date, lag)
        else
          remove_lag(date, -lag)
        end
      end

      def start_date(due_date, duration)
        assert_strictly_positive_duration(duration)
        return nil unless due_date && duration

        start_date = latest_working_day(due_date)
        until duration <= 1 && working?(start_date)
          start_date -= 1
          duration -= 1 if working?(start_date)
        end
        start_date
      end

      def due_date(start_date, duration)
        assert_strictly_positive_duration(duration)
        return nil unless start_date && duration

        due_date = soonest_working_day(start_date)
        until duration <= 1 && working?(due_date)
          due_date += 1
          duration -= 1 if working?(due_date)
        end
        due_date
      end

      def soonest_working_day(date)
        return unless date

        until working?(date)
          date += 1
        end

        date
      end

      def working?(date)
        working_week_day?(date) && working_specific_date?(date)
      end

      def non_working?(date)
        !working?(date)
      end

      private

      def assert_strictly_positive_duration(duration)
        raise ArgumentError, "duration must be strictly positive" if duration.is_a?(Integer) && duration <= 0
      end

      def add_lag(date, lag)
        date_with_lag = date.next_day
        while lag != 0
          lag -= 1 if working?(date_with_lag)
          date_with_lag += 1
        end
        date_with_lag
      end

      def remove_lag(date, lag)
        date_with_lag = date
        while lag != 0
          lag -= 1 if working?(date_with_lag)
          next if lag == 0

          date_with_lag -= 1
        end
        date_with_lag
      end

      def latest_working_day(date)
        return unless date

        until working?(date)
          date -= 1
        end
        date
      end

      def working_week_day?(date)
        assert_some_working_week_days_exist
        working_week_days[date.wday]
      end

      def working_specific_date?(date)
        non_working_dates.exclude?(date)
      end

      def assert_some_working_week_days_exist
        return if @working_week_days_exist

        if working_week_days.all?(false)
          raise "cannot have all week days as non-working days"
        end

        @working_week_days_exist = true
      end

      def working_week_days
        return @working_week_days if defined?(@working_week_days)

        # WeekDay day of the week is stored as ISO, meaning Monday is 1 and Sunday is 7.
        # Ruby Date#wday value for Sunday is 0 and it goes until 6 Saturday.
        # To accommodate both versions 0-6, 1-7, an array of 8 elements is created
        # where array[0] = array[7] = value for Sunday
        #
        # Since Setting.working_days can be empty, the initial array is
        # built with all days considered working (value is `true`)

        @working_week_days = [true] * 8

        WeekDay.all.each do |week_day|
          @working_week_days[week_day.day] = week_day.working
        end

        @working_week_days[0] = @working_week_days[7] # value for Sunday is present at index 0 AND index 7
        @working_week_days
      end

      def non_working_dates
        @non_working_dates ||= RequestStore.fetch(:work_package_non_working_dates) { Set.new(NonWorkingDay.pluck(:date)) }
      end
    end
  end
end

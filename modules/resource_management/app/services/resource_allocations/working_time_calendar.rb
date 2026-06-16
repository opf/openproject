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

module ResourceAllocations
  # Computes how many minutes a user can work on each day of a date range.
  #
  # Capacity is purely user-driven: the system-wide `Setting.working_days` is
  # intentionally NOT consulted, because a user's `UserWorkingHours` already
  # encodes which weekdays they work (a zero-minute weekday is a non-working day
  # for them). A day's capacity is zero when the user works zero minutes that
  # weekday, the day falls inside one of the user's `UserNonWorkingTime` ranges,
  # or the day is a global `NonWorkingDay` (holiday). Otherwise it is the
  # weekday's minutes from the `UserWorkingHours` record valid on that date,
  # scaled by the record's `availability_factor`.
  class WorkingTimeCalendar
    WDAY_TO_COLUMN = UserWorkingHours::DAY_ABBR_INDEX.invert.freeze

    def initialize(user:, range:)
      @user = user
      @range = range
      @working_hours = UserWorkingHours.for_user(user).order(:valid_from).to_a
      @holidays = NonWorkingDay.for_dates(range).pluck(:date).to_set
      @non_working_ranges = load_non_working_ranges(range)
      @capacities = {}
      @prefix = build_prefix
    end

    # Capacity in minutes the user can work on the given date.
    def capacity_on(date)
      @capacities[date] ||= compute_capacity(date)
    end

    def each_day
      return enum_for(:each_day) unless block_given?

      @range.each { |date| yield date, capacity_on(date) }
    end

    # Total capacity across the whole range.
    def total
      prefix_total(@range.end)
    end

    # Cumulative capacity from the start of the range up to and including `date`,
    # clamped to the range bounds. Enables O(1) interval capacity sums.
    def prefix_total(date)
      return 0 if date < @range.begin

      @prefix[[date, @range.end].min]
    end

    private

    def load_non_working_ranges(range)
      UserNonWorkingTime
        .for_user(@user)
        .overlapping(range)
        .map { |nwt| nwt.start_date..nwt.end_date }
    end

    def build_prefix
      acc = 0
      @range.each_with_object({}) do |date, prefix|
        acc += capacity_on(date)
        prefix[date] = acc
      end
    end

    def compute_capacity(date)
      return 0 if @holidays.include?(date)
      return 0 if non_working?(date)

      working_hours = working_hours_for(date)
      return 0 if working_hours.nil?

      minutes = working_hours.public_send(WDAY_TO_COLUMN.fetch(date.wday))
      return 0 if minutes.zero?

      (minutes * working_hours.availability_factor / 100.0).round
    end

    def non_working?(date)
      @non_working_ranges.any? { |nwt_range| nwt_range.cover?(date) }
    end

    # The applicable schedule is the most recent one effective on or before the
    # date (mirrors UserWorkingHours.valid_for_date, but batched over the range).
    def working_hours_for(date)
      @working_hours.reverse_each.find { |working_hours| working_hours.valid_from <= date }
    end
  end
end

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

module ResourceAllocations
  class Availability
    def initialize(user:)
      @user = user
    end

    def overbooked?
      overbooked_allocation_ids.any?
    end

    def overbooked_dates
      @overbooked_dates ||= overbooked_entries.map(&:allocated_on).uniq.sort
    end

    def overbooked_dates_of(allocation)
      overbooked_entries.select { |entry| entry.resource_allocation_id == allocation.id }.map(&:allocated_on).sort
    end

    def overbooked_allocation_ids
      @overbooked_allocation_ids ||= ResourceAllocation.allocated.for_principal(@user).overbooked.pluck(:id).to_set
    end

    # The allocation (or its changes) is not saved, so the stored schedule is
    # resumed with and without it from the earliest start it had or has: before
    # that day, it has no minutes placed in either variant.
    def overbooking_with(allocation)
      from = [allocation.start_date, allocation.start_date_in_database].compact.min
      baseline, prospective = resumed_fits(allocation, from)
      added_overtime = added_overtime_by_date(prospective, baseline)
      overtime_dates = added_overtime.keys

      ProspectiveOverbooking.new(
        overtime_minutes: added_overtime.values.sum,
        period: (overtime_dates.min..overtime_dates.max if overtime_dates.any?),
        unplannable: prospective.unplannable.key?(allocation)
      )
    end

    def utilization_ratio(range)
      capacity = capacity_minutes_within(range)
      return if capacity.zero?

      ((scheduled_minutes_within(range).to_f / capacity) * 100).round
    end

    # The minutes the user works within the given range, before anything booked
    # against them. A user without a working schedule reads zero here, where
    # their capacity is unknown rather than absent.
    def capacity_minutes_within(range)
      @capacity_minutes_within ||= {}
      @capacity_minutes_within[range] ||= WorkingTimeCalendar.new(user: @user, range:).total
    end

    def scheduled_minutes_within(range)
      ScheduledEntry.where(user: @user, allocated_on: range).sum(:minutes)
    end

    private

    def overbooked_entries
      @overbooked_entries ||= ScheduledEntry
                                .where(user: @user)
                                .where(allocated_on: ScheduledEntry.where(user: @user).with_overtime
                                                                   .select(:allocated_on))
                                .select(:resource_allocation_id, :allocated_on)
                                .to_a
    end

    def resumed_fits(allocation, from)
      others = ResourceAllocation.allocated.for_principal(@user).where(end_date: from..).where.not(id: allocation.id).to_a
      remaining = ScheduledEntry.remaining_minutes_by_allocation(others, on: from)
      prospective = others + [allocation]
      calendar = calendar_for(prospective)

      [
        FitCalculator.new(calendar:, allocations: others, from:, remaining:).call,
        FitCalculator.new(calendar:, allocations: prospective, from:,
                          remaining: remaining.merge(allocation => allocation.allocated_time)).call
      ]
    end

    def calendar_for(allocations)
      range = allocations.map(&:start_date).min..allocations.map(&:end_date).max
      WorkingTimeCalendar.new(user: @user, range:)
    end

    def added_overtime_by_date(prospective, baseline)
      baseline_overtime = overtime_by_date(baseline)

      overtime_by_date(prospective).each_with_object({}) do |(date, minutes), added|
        difference = minutes - baseline_overtime[date]
        added[date] = difference if difference.positive?
      end
    end

    def overtime_by_date(result)
      result.overtime.values.each_with_object(Hash.new(0)) do |minutes_by_date, sums|
        minutes_by_date.each { |date, minutes| sums[date] += minutes }
      end
    end
  end
end

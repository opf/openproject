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
  # Load is every `allocated` allocation the user is the principal of, across all
  # projects (capacity is a user-level property). Filter-based allocations have no
  # principal and are excluded.
  class Availability
    # `allocations` takes the user's `allocated` allocations when the caller
    # already loaded them (e.g. in bulk for several users); they are queried
    # lazily otherwise.
    # `global_non_working_days` is forwarded to the working-time calendars so a
    # caller handling several users can share one `NonWorkingDay` lookup; it must
    # cover the span of the user's allocations. Fetched per calendar when omitted.
    def initialize(user:, allocations: nil, global_non_working_days: nil)
      @user = user
      @allocations = allocations
      @global_non_working_days = global_non_working_days
    end

    def overbooked?
      overbooked_allocation_ids.any?
    end

    def overbooked_dates
      @overbooked_dates ||= optimal_schedule.overbooked_dates
    end

    def overbooked_dates_of(allocation)
      overbooked_dates.select { |date| optimal_schedule.allocations_on(date).include?(allocation) }
    end

    def overbooked_allocation_ids
      @overbooked_allocation_ids ||=
        (overbooked_dates.flat_map { |date| optimal_schedule.allocations_on(date) } + optimal_schedule.unplannable)
          .to_set(&:id)
    end

    def optimal_schedule
      @optimal_schedule ||= schedule_for(allocations)
    end

    def overbooking_with(allocation)
      others = allocations.reject { |other| other.id == allocation.id }
      prospective_schedule = schedule_for(others + [allocation])
      baseline_schedule = others.size == allocations.size ? optimal_schedule : schedule_for(others)

      ProspectiveOverbooking.new(
        days: overbooked_days(prospective_schedule, baseline_schedule, allocation),
        unplannable: prospective_schedule.unplannable.include?(allocation)
      )
    end

    # The user's working schedules effective within the given date range, in
    # chronological order: the schedule active at the range start (if any)
    # followed by any schedules taking effect within the range. Empty when no
    # schedule is in effect at any point of the range.
    #
    # @return [Array<UserWorkingHours>]
    def working_schedules(range)
      records = UserWorkingHours
                  .for_user(@user)
                  .where(valid_from: ..range.end)
                  .order(:valid_from)
                  .to_a
      active_index = records.rindex { |record| record.valid_from <= range.begin }

      active_index.nil? ? records : records[active_index..]
    end

    # The leading part of the range before the user's earliest working schedule
    # takes effect, which WorkingTimeCalendar counts as zero capacity. Nil when
    # a schedule covers the whole range.
    #
    # @return [Range<Date>, nil]
    def unscheduled_range(range)
      earliest = UserWorkingHours.for_user(@user).minimum(:valid_from)
      return range if earliest.nil?
      return if earliest <= range.begin

      range.begin..[earliest - 1, range.end].min
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
      @capacity_minutes_within[range] ||=
        WorkingTimeCalendar.new(user: @user, range:, global_non_working_days: @global_non_working_days).total
    end

    def scheduled_minutes_within(range)
      optimal_schedule.by_date.sum { |date, entries| range.cover?(date) ? entries.sum(&:minutes) : 0 }
    end

    private

    def allocations
      @allocations ||= ResourceAllocation
                         .allocated
                         .for_principal(@user)
                         .includes(:entity)
                         .to_a
    end

    def schedule_for(scheduled)
      return OptimalSchedule.new if scheduled.empty?

      range = scheduled.map(&:start_date).min..scheduled.map(&:end_date).max
      calendar = WorkingTimeCalendar.new(user: @user, range:, global_non_working_days: @global_non_working_days)
      result = FitCalculator.new(calendar:, allocations: scheduled).call

      OptimalSchedule.new(by_date: entries_by_date(result), unplannable: result.unplannable.keys, calendar:)
    end

    def overbooked_days(prospective_schedule, baseline_schedule, allocation)
      prospective_schedule.overbooked_dates.filter_map do |date|
        overtime = prospective_schedule.overtime_on(date)
        next if overtime <= baseline_schedule.overtime_on(date)

        entries = prospective_schedule.entries_on(date)
        added = entries.select { |entry| entry.allocation == allocation }.sum(&:minutes)
        OverbookedDay.new(date:, working_minutes: prospective_schedule.capacity_on(date),
                          planned_minutes: entries.sum(&:minutes) - added, added_minutes: added, overtime_minutes: overtime)
      end
    end

    def entries_by_date(result)
      (result.placements.keys | result.overtime.keys)
        .flat_map { |allocation| scheduled_entries(allocation, result) }
        .group_by(&:allocated_on)
        .transform_values { |entries| entries.sort_by(&:minutes) }
    end

    def scheduled_entries(allocation, result)
      placed = result.placements.fetch(allocation, {})
      overtime = result.overtime.fetch(allocation, {})

      (placed.keys | overtime.keys).map do |date|
        overtime_minutes = overtime.fetch(date, 0)
        ScheduledEntry.new(
          allocation:,
          work_package: allocation.entity,
          allocated_on: date,
          minutes: placed.fetch(date, 0) + overtime_minutes,
          overtime_minutes:
        )
      end
    end
  end
end

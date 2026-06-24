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
  # Answers availability questions for a single user by combining their working
  # time capacity with the allocations booked against them.
  #
  # Load is every `allocated` allocation the user is the principal of, across all
  # projects (capacity is a user-level property). Filter-based allocations have no
  # principal and are excluded.
  class Availability
    # Identifies the prospective allocation amongst the existing work items when
    # checking a not-yet-persisted allocation.
    CANDIDATE_ID = :candidate

    # `allocations` takes the user's `allocated` allocations when the caller
    # already loaded them (e.g. in bulk for several users); they are queried
    # lazily otherwise.
    def initialize(user:, allocations: nil)
      @user = user
      @allocations = allocations
    end

    def overbooked?
      overbooked_ranges.any?
    end

    # @return [Array<ResourceAllocations::OverbookedRange>] ranges to highlight,
    #   each carrying the work packages forced into it.
    def overbooked_ranges
      @overbooked_ranges ||=
        if items.empty?
          []
        else
          OverbookingAnalysis.new(calendar: base_calendar, items:).call
        end
    end

    def overbooked_on?(date)
      overbooked_ranges.any? { |range| range.covers?(date) }
    end

    # The user's working time optimally allocated to their work packages.
    def optimal_schedule
      @optimal_schedule ||= build_optimal_schedule
    end

    # Whether a prospective allocation would still fit. `exclude_id` drops an
    # existing allocation from the check (e.g. the one being edited).
    def fits?(start_date:, end_date:, minutes:, exclude_id: nil)
      overbooking_with(start_date:, end_date:, minutes:, exclude_id:).empty?
    end

    # The overbooked ranges that would result from adding a prospective
    # allocation. The candidate is included in the ranges' items (carrying
    # `work_package_id`) so a warning can list and flag it. Empty when it fits.
    # `exclude_id` drops an existing allocation from the check (e.g. the one
    # being edited).
    def overbooking_with(start_date:, end_date:, minutes:, work_package_id: nil, exclude_id: nil)
      candidate = WorkItem.new(id: CANDIDATE_ID, start_date:, end_date:, minutes:, work_package_id:)
      work_items = items.reject { |item| item.id == exclude_id } << candidate

      OverbookingAnalysis.new(calendar: calendar_for(work_items), items: work_items).call
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

    def utilization_ratio(range)
      capacity = WorkingTimeCalendar.new(user: @user, range:).total
      return if capacity.zero?

      ((booked_minutes_within(range).to_f / capacity) * 100).round
    end

    private

    def allocations
      @allocations ||= ResourceAllocation
                         .allocated
                         .for_principal(@user)
                         .includes(:entity)
                         .to_a
    end

    def items
      @items ||= allocations.map { |allocation| WorkItem.from_allocation(allocation) }
    end

    def base_calendar
      @base_calendar ||= calendar_for(items)
    end

    def calendar_for(work_items)
      range = work_items.map(&:start_date).min..work_items.map(&:end_date).max
      WorkingTimeCalendar.new(user: @user, range:)
    end

    def build_optimal_schedule
      return OptimalSchedule.new(by_date: {}, capacity_by_date: {}) if items.empty?

      result = FitCalculator.new(calendar: base_calendar, items:).call
      allocations_by_id = allocations.index_by(&:id)

      OptimalSchedule.new(
        by_date: placements_by_date(result.placements, allocations_by_id),
        capacity_by_date: base_calendar.each_day.to_h
      )
    end

    def placements_by_date(placements, allocations_by_id)
      by_date = Hash.new { |hash, date| hash[date] = [] }

      placements.each do |allocation_id, minutes_per_day|
        allocation = allocations_by_id.fetch(allocation_id)
        minutes_per_day.each do |date, minutes|
          by_date[date] << ScheduledEntry.new(allocation:, work_package: allocation.entity, minutes:)
        end
      end

      by_date.each_value { |entries| entries.sort_by!(&:minutes) }
      by_date
    end

    def booked_minutes_within(range)
      return 0 if items.empty?

      allocations.sum { |allocation| allocation_minutes_within(allocation, range) }
    end

    def allocation_minutes_within(allocation, range)
      overlap_start = [allocation.start_date, range.begin].max
      overlap_end = [allocation.end_date, range.end].min
      return 0 if overlap_start > overlap_end

      total = capacity_between(allocation.start_date, allocation.end_date)
      return 0 if total.zero?

      overlap = capacity_between(overlap_start, overlap_end)

      (allocation.allocated_time * overlap.to_f / total).round
    end

    def capacity_between(first, last)
      base_calendar.prefix_total(last) - base_calendar.prefix_total(first - 1)
    end
  end
end

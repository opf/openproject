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
  module ScheduleHelpers
    StaticCalendar = Data.define(:capacities) do
      def capacity_on(date) = capacities.fetch(date, 0)
    end

    def static_calendar(capacities)
      StaticCalendar.new(capacities:)
    end

    StubAllocation = Data.define(:id, :start_date, :end_date, :allocated_time)

    def allocation(id, start_date, end_date, minutes)
      StubAllocation.new(id:, start_date:, end_date:, allocated_time: minutes)
    end

    def scheduled_entry(allocation, date, minutes, overtime_minutes: 0)
      ScheduledEntry.new(allocation:, allocated_on: date, minutes:, overtime_minutes:)
    end

    def stored_schedule(user)
      ScheduledEntry
        .where(user:)
        .pluck(:resource_allocation_id, :allocated_on, :minutes, :overtime_minutes)
        .map do |allocation_id, allocated_on, minutes, overtime_minutes|
          { allocation_id:, allocated_on:, minutes:, overtime_minutes: }
        end
    end

    def computed_schedule(user)
      allocations = ResourceAllocation.allocated.for_principal(user).to_a
      return [] if allocations.empty?

      range = allocations.map(&:start_date).min..allocations.map(&:end_date).max
      result = FitCalculator.new(calendar: WorkingTimeCalendar.new(user:, range:), allocations:).call

      allocations.flat_map do |allocation|
        placed = result.placements.fetch(allocation, {})
        overtime = result.overtime.fetch(allocation, {})
        scheduled_dates = placed.keys | overtime.keys

        scheduled_dates.map do |allocated_on|
          overtime_minutes = overtime.fetch(allocated_on, 0)
          { allocation_id: allocation.id, allocated_on:,
            minutes: placed.fetch(allocated_on, 0) + overtime_minutes, overtime_minutes: }
        end
      end
    end
  end
end

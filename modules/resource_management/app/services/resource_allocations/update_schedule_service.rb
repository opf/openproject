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
  # Brings the stored schedule of each user up to date with their allocations,
  # resuming the sweep `from` the earliest changed date (`nil` rebuilds it
  # completely). Placements before that date are final, but overtime is spread
  # over each allocation's whole window, so overtime before it may change too.
  #
  # When an allocation moves between users, pass its previous principal first,
  # so that its entries are gone before the new principal writes them.
  class UpdateScheduleService
    def call(users:, from:)
      ActiveRecord::Base.transaction do
        ScheduledEntry.lock_schedules_of(users)
        users.each { |user| update_schedule_of(user, from) }
      end
    end

    private

    def update_schedule_of(user, from)
      allocations = affected_allocations(user, from)
      stored = stored_entries(user, allocations, from).index_by { |entry| [entry.resource_allocation_id, entry.allocated_on] }
      desired = allocations.empty? ? {} : desired_rows(user, fit(user, allocations, from), stored, from)

      upsert_changed(desired, stored)
      delete_absent(desired, stored)
    end

    def affected_allocations(user, from)
      allocations = ResourceAllocation.allocated.for_principal(user)
      allocations = allocations.where(end_date: from..) if from
      allocations.to_a
    end

    def stored_entries(user, allocations, from)
      entries = ScheduledEntry.where(user:)
      return entries if from.nil?

      entries.where(allocation: allocations).or(entries.where(allocated_on: from..))
    end

    def desired_rows(user, result, stored, from)
      placed = stored_placed_minutes_before(from, stored).merge(minutes_by_key(result.placements))
      overtime = minutes_by_key(result.overtime)
      scheduled_allocation_days = placed.keys | overtime.keys

      scheduled_allocation_days
        .index_with { |key| row(user, key, placed.fetch(key, 0), overtime.fetch(key, 0)) }
        .reject { |_key, row| row[:minutes].zero? }
    end

    def row(user, (allocation_id, allocated_on), placed_minutes, overtime_minutes)
      { user_id: user.id, resource_allocation_id: allocation_id, allocated_on:,
        minutes: placed_minutes + overtime_minutes, overtime_minutes: }
    end

    def fit(user, allocations, from)
      range = allocations.map(&:start_date).min..allocations.map(&:end_date).max
      calendar = WorkingTimeCalendar.new(user:, range:)
      remaining = ScheduledEntry.remaining_minutes_by_allocation(allocations, on: from)

      FitCalculator.new(calendar:, allocations:, from:, remaining:).call
    end

    def stored_placed_minutes_before(from, stored)
      return {} if from.nil?

      stored
        .select { |(_allocation_id, date), _entry| date < from }
        .transform_values { |entry| entry.minutes - entry.overtime_minutes }
    end

    def minutes_by_key(minutes_by_allocation)
      minutes_by_allocation.each_with_object({}) do |(allocation, minutes_by_date), result|
        minutes_by_date.each { |date, minutes| result[[allocation.id, date]] = minutes }
      end
    end

    def upsert_changed(desired, stored)
      changed = desired.reject { |key, row| unchanged?(stored[key], row) }.values
      return if changed.empty?

      ScheduledEntry.upsert_all(changed, unique_by: %i[resource_allocation_id allocated_on], record_timestamps: false)
    end

    def unchanged?(entry, row)
      entry && entry.user_id == row[:user_id] && entry.minutes == row[:minutes] &&
        entry.overtime_minutes == row[:overtime_minutes]
    end

    def delete_absent(desired, stored)
      absent_ids = stored.except(*desired.keys).values.map(&:id)
      ScheduledEntry.where(id: absent_ids).delete_all if absent_ids.any?
    end
  end
end

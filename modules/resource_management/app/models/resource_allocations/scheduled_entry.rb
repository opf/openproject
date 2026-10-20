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
  # A single allocation's share of a day in a user's schedule: `minutes` of the
  # `allocation` placed on the `allocated_on` day. `minutes` includes the
  # `overtime_minutes` beyond the user's working hours.
  class ScheduledEntry < ApplicationRecord
    self.table_name = "resource_allocation_scheduled_entries"

    belongs_to :allocation, class_name: "ResourceAllocation", foreign_key: :resource_allocation_id, inverse_of: false
    belongs_to :user

    scope :with_overtime, -> { where(arel_table[:overtime_minutes].gt(0)) }

    # Writes that cascade into the entries (e.g. deleting allocations) take this
    # lock before writing. Otherwise a recomputation holding the lock waits for
    # those rows while the writer waits for the lock.
    def self.lock_schedules_of(users)
      users.sort_by(&:id).each do |user|
        with_advisory_lock!("resource_allocation_schedule_#{user.id}", transaction: true, blocking: true)
      end
    end

    def self.remaining_minutes_by_allocation(allocations, on:)
      placed = on ? placed_minutes_by_allocation_id(allocations, before: on) : {}
      allocations.index_with { |allocation| allocation.allocated_time - placed.fetch(allocation.id, 0) }
    end

    def self.placed_minutes_by_allocation_id(allocations, before:)
      where(allocation: allocations, allocated_on: ...before)
        .group(:resource_allocation_id)
        .sum("minutes - overtime_minutes")
    end

    def work_package = allocation.entity
  end
end

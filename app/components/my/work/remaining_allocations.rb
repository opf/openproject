# frozen_string_literal: true

# -- copyright
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
# ++

module My
  module Work
    # What is left of each allocation once the time logged on its work package that day
    # is taken off, mirroring remainingHours in the stack and calendar views.
    class RemainingAllocations
      # `allocations` is a ResourceAllocations::AllocatedTimeFor, or nil when allocations are
      # not shown at all. `dates` narrows them down to part of the dates they were loaded for.
      def self.call(allocations:, time_entries:, dates: nil)
        new(allocations:, time_entries:, dates:).call
      end

      def initialize(allocations:, time_entries:, dates: nil)
        @allocations = allocations
        @time_entries = time_entries
        @dates = dates
      end

      # @return [Array<My::Work::AllocationRow::Entry>]
      def call
        return [] unless @allocations

        @allocations.items.filter_map do |entry|
          next if @dates&.exclude?(entry.allocated_on)

          visible = @allocations.visible?(entry)
          hours = ((entry.minutes / 60.0) - logged_hours_on(entry, visible:)).round(2)

          AllocationRow::Entry.new(scheduled_entry: entry, visible:, hours:) if hours.positive?
        end
      end

      private

      # A running timer has no final hours yet.
      def logged_hours_on(entry, visible:)
        return 0 unless visible

        @time_entries
          .select do |time_entry|
            !time_entry.ongoing? && time_entry.entity == entry.work_package && time_entry.spent_on == entry.allocated_on
          end
          .sum(&:hours)
      end
    end
  end
end

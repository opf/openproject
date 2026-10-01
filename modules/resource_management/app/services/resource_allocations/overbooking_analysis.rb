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
  # Finds the date ranges in which a user is overbooked.
  #
  # Work items are divisible: each item's minutes may be spread across any days
  # within its window. A set of items therefore fits iff, for every date interval
  # [a, b], the work *forced* into it (items whose whole window lies within [a, b])
  # does not exceed the user's capacity across those days. This is the standard
  # single-resource divisible-scheduling (Hall/transportation) feasibility
  # condition; the intervals that violate it are exactly where the user is
  # overbooked.
  #
  # It is enough to test intervals bounded by item start and end dates, since
  # capacity only ever grows by adding days while forced demand only changes at
  # those boundaries.
  class OverbookingAnalysis
    Violation = Data.define(:start_date, :end_date, :items, :over_by_minutes)
    private_constant :Violation

    def initialize(calendar:, items:)
      @calendar = calendar
      @items = items
    end

    # @return [Array<OverbookedRange>] contiguous overbooked ranges, each with the
    #   work packages forced into it and the largest amount it is over by.
    def call
      violations = compute_violations
      return [] if violations.empty?

      group_into_ranges(violations)
    end

    private

    def compute_violations
      lower_bounds = @items.map(&:start_date).uniq.sort
      upper_bounds = @items.map(&:end_date).uniq.sort

      lower_bounds.each_with_object([]) do |from_date, violations|
        upper_bounds.each do |to_date|
          next if to_date < from_date

          violation = violation_for(from_date, to_date)
          violations << violation if violation
        end
      end
    end

    def violation_for(from_date, to_date)
      forced = @items.select { |item| item.start_date >= from_date && item.end_date <= to_date }
      return if forced.empty?

      over_by = forced.sum(&:minutes) - capacity_between(from_date, to_date)
      return if over_by <= 0

      Violation.new(start_date: from_date, end_date: to_date, items: forced, over_by_minutes: over_by)
    end

    def capacity_between(from_date, to_date)
      @calendar.prefix_total(to_date) - @calendar.prefix_total(from_date - 1)
    end

    # Each violating interval's days are fully covered, so every violation falls
    # entirely within exactly one contiguous block of covered days.
    def group_into_ranges(violations)
      covered_days = violations.flat_map { |violation| (violation.start_date..violation.end_date).to_a }.uniq.sort

      consecutive_blocks(covered_days).map { |first, last| overbooked_range(first, last, violations) }
    end

    def overbooked_range(first, last, violations)
      in_block = violations.select { |violation| violation.start_date >= first && violation.end_date <= last }
      items = in_block.flat_map(&:items).uniq(&:id)

      OverbookedRange.new(
        start_date: first,
        end_date: last,
        items:,
        work_package_ids: items.filter_map(&:work_package_id).uniq,
        over_by_minutes: in_block.map(&:over_by_minutes).max,
        available_minutes: capacity_between(first, last)
      )
    end

    def consecutive_blocks(dates)
      dates
        .slice_when { |previous, current| current != previous + 1 }
        .map { |group| [group.first, group.last] }
    end
  end
end

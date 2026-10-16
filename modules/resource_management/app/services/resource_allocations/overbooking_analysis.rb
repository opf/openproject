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
      items_by_end_date = @items.sort_by(&:end_date)
      upper_bounds = @items.map(&:end_date).uniq.sort

      @items.map(&:start_date).uniq.sort.flat_map do |from_date|
        starting = items_by_end_date.select { |item| item.start_date >= from_date }
        violations_from(from_date, starting, upper_bounds.select { |to_date| to_date >= from_date })
      end
    end

    # Walks the upper bounds in ascending order, adding up the work of the
    # items (ordered by end date) whose window closes within each interval.
    def violations_from(from_date, starting, upper_bounds)
      forced_count = 0
      forced_minutes = 0

      upper_bounds.filter_map do |to_date|
        while forced_count < starting.size && starting[forced_count].end_date <= to_date
          forced_minutes += starting[forced_count].minutes
          forced_count += 1
        end
        next if forced_count.zero?

        over_by = forced_minutes - capacity_between(from_date, to_date)
        next if over_by <= 0

        forced = @items.intersection(starting.first(forced_count))
        Violation.new(start_date: from_date, end_date: to_date, items: forced, over_by_minutes: over_by)
      end
    end

    def capacity_between(from_date, to_date)
      @calendar.prefix_total(to_date) - @calendar.prefix_total(from_date - 1)
    end

    # Each violating interval's days are fully covered, so every violation falls
    # entirely within exactly one contiguous block of covered days.
    def group_into_ranges(violations)
      blocks = merged_blocks(violations)
      by_block = violations.group_by { |violation| blocks.bsearch { |_first, last| last >= violation.start_date } }

      blocks.map { |first, last| overbooked_range(first, last, by_block.fetch([first, last])) }
    end

    # Joins violating intervals that overlap or touch into [first, last] blocks.
    def merged_blocks(violations)
      violations.sort_by(&:start_date).each_with_object([]) do |violation, blocks|
        current = blocks.last
        if current && violation.start_date <= current.last + 1
          current[1] = [current.last, violation.end_date].max
        else
          blocks << [violation.start_date, violation.end_date]
        end
      end
    end

    def overbooked_range(first, last, in_block)
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
  end
end

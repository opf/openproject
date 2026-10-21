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
  # Places divisible allocations onto a user's daily capacity using
  # Earliest-Deadline-First water-filling: walking days chronologically, each
  # day is filled from the active allocations (window contains the day, work
  # left) in order of nearest end date. For single-resource divisible
  # scheduling with release dates and deadlines this is optimal for
  # feasibility, so any minutes left over could not have fit under any
  # placement.
  #
  # Those leftover minutes are spread as `overtime` over the working days of
  # the allocation's own window, in proportion to each day's capacity.
  # Allocations whose window has no working day report them as `unplannable`
  # instead.
  #
  # The `calendar` must span the allocations' combined window.
  #
  # A sweep can resume `from` a date, given the minutes each allocation still
  # had `remaining` at its start. Placements before that date are then not part
  # of the result, while overtime still covers each allocation's whole window.
  class FitCalculator
    Result = Data.define(:placements, :overtime, :unplannable) do
      def feasible? = overtime.empty? && unplannable.empty?
    end

    def initialize(calendar:, allocations:, from: nil, remaining: nil)
      @calendar = calendar
      @allocations = allocations
      @from = from
      @remaining = remaining || allocations.index_with(&:allocated_time)
    end

    def call
      remaining = @remaining.dup
      placements = Hash.new { |hash, allocation| hash[allocation] = {} }

      each_day_with_active_allocations(remaining) do |date, active|
        fill_day(date, active, remaining, placements)
      end

      overtime, unplannable = distribute_leftover(remaining)

      Result.new(placements:, overtime:, unplannable:)
    end

    private

    def distribute_leftover(remaining)
      overtime = {}
      unplannable = {}

      remaining.each do |allocation, minutes|
        next unless minutes.positive?

        shares = overtime_shares(allocation, minutes)
        if shares.empty?
          unplannable[allocation] = minutes
        else
          overtime[allocation] = shares
        end
      end

      [overtime, unplannable]
    end

    def overtime_shares(allocation, minutes)
      capacities = working_day_capacities(allocation)
      total = capacities.values.sum
      return {} if total.zero?

      exact = capacities.transform_values { |capacity| Rational(minutes * capacity, total) }
      round_keeping_total(exact, minutes).select { |_date, share| share.positive? }
    end

    # Rounds each share down and hands the minutes this leaves out one by one,
    # by largest fractional part and earlier date first, so the shares add up
    # to exactly `total`.
    def round_keeping_total(exact, total)
      shares = exact.transform_values(&:floor)
      leftover = total - shares.values.sum

      exact.keys
        .sort_by { |date| [exact[date].floor - exact[date], date] }
        .first(leftover)
        .each { |date| shares[date] += 1 }

      shares
    end

    def working_day_capacities(allocation)
      (allocation.start_date..allocation.end_date).filter_map do |date|
        capacity = @calendar.capacity_on(date)
        [date, capacity] if capacity.positive?
      end.to_h
    end

    def fill_day(date, active, remaining, placements)
      free = @calendar.capacity_on(date)
      active.each do |allocation|
        break if free.zero?

        take = [remaining[allocation], free].min
        placements[allocation][date] = take
        remaining[allocation] -= take
        free -= take
      end
    end

    def each_day_with_active_allocations(remaining)
      pending = allocations_with_work_by_start_date(remaining)
      active = []
      date = first_day(pending)

      while date
        activate_starting_on(date, pending, active)
        drop_expired_before(date, active)

        yield date, active

        active.reject! { |allocation| remaining[allocation].zero? }
        date = active.empty? ? pending.first&.start_date : date + 1
      end
    end

    def first_day(pending)
      return if pending.empty?

      [pending.first.start_date, @from].compact.max
    end

    def allocations_with_work_by_start_date(remaining)
      @allocations.select { |allocation| remaining[allocation].positive? }.sort_by(&:start_date)
    end

    def activate_starting_on(date, pending, active)
      while pending.any? && pending.first.start_date <= date
        allocation = pending.shift
        index = active.bsearch_index { |other| (priority(other) <=> priority(allocation)).positive? } || active.size
        active.insert(index, allocation)
      end
    end

    def drop_expired_before(date, active)
      active.shift while active.any? && active.first.end_date < date
    end

    # An allocation that is not persisted yet loses ties against every
    # persisted one.
    def priority(allocation)
      [allocation.end_date, allocation.start_date, allocation.id || Float::INFINITY]
    end
  end
end

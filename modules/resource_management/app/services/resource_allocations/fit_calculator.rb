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
  # Places divisible work items onto a user's daily capacity using
  # Earliest-Deadline-First water-filling: walking days chronologically, each
  # day is filled from the active items (window contains the day, work left)
  # in order of nearest end date. For single-resource divisible scheduling with
  # release dates and deadlines this is optimal for feasibility, so any minutes
  # left over could not have fit under any placement.
  #
  # The `calendar` must span the items' combined window.
  class FitCalculator
    Result = Data.define(:placements, :daily_load, :unscheduled) do
      def feasible? = unscheduled.empty?
    end

    def initialize(calendar:, items:)
      @calendar = calendar
      @items = items
    end

    def call
      remaining = @items.to_h { |item| [item.id, item.minutes] }
      placements = Hash.new { |hash, id| hash[id] = {} }
      daily_load = {}

      each_day { |date| fill_day(date, remaining, placements, daily_load) }

      Result.new(
        placements:,
        daily_load:,
        unscheduled: remaining.select { |_id, minutes| minutes.positive? }
      )
    end

    private

    def fill_day(date, remaining, placements, daily_load)
      capacity = @calendar.capacity_on(date)
      return if capacity.zero?

      free = place_items(date, capacity, remaining, placements)
      used = capacity - free
      daily_load[date] = used if used.positive?
    end

    # Fills the day from the active items in earliest-deadline order, returning
    # the capacity left over.
    def place_items(date, capacity, remaining, placements)
      free = capacity
      active_items(date, remaining).each do |item|
        break if free.zero?

        take = [remaining[item.id], free].min
        next if take.zero?

        placements[item.id][date] = take
        remaining[item.id] -= take
        free -= take
      end
      free
    end

    def each_day(&)
      return if @items.empty?

      from = @items.map(&:start_date).min
      to = @items.map(&:end_date).max
      (from..to).each(&)
    end

    def active_items(date, remaining)
      @items
        .select { |item| date.between?(item.start_date, item.end_date) && remaining[item.id].positive? }
        .sort_by { |item| [item.end_date, item.start_date, item.id] }
    end
  end
end

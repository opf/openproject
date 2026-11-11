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

module Sprints
  # One straight line from an origin to a target value at +finish+, measured in working days rather
  # than in clock time: +slope+ is what a whole day takes, and every point is that slope applied to
  # the distance still to run. Non working days are no distance at all, which is what leaves them flat.
  # +finish+ may fall partway through a day, in which case the rest of that day is no distance either.
  # Only two points can land inside a day -- the one the line opens on and the one the chart closes on.
  class WorkingDayLine
    def initialize(window:, finish:)
      @window = window
      @finish = finish
    end

    def from(origin, to:)
      origin_from = origin.at.in_time_zone(zone)
      days = days_until_finish(origin_from)

      return [origin] if days.empty?

      capacity = still_ahead(days, days.first, origin_from)

      return [origin] unless capacity.positive?

      slope = (origin.value - to) / capacity

      points_along(days, slope:, to:).prepend(origin)
    end

    private

    attr_reader :window, :finish

    delegate :charted_from, :charted_until, :zone, to: :window

    def points_along(days, slope:, to:)
      samples(days).map do |day, at|
        ChartPoint.new(at:, value: to + (slope * still_ahead(days, day, at)))
      end
    end

    # What the line has left to spend after +from+, which falls inside +day+. Taken at the
    # origin it is the whole capacity, and at the last sample it is nothing.
    def still_ahead(days, day, from)
      working_days_after(days, day.date) + part_of_day_after(day, from) - part_of_day_after(days.last, finish)
    end

    # Each day paired with the last moment the series has a value in it: the day's close, or where
    # the chart closes when that comes first. Days lying wholly beyond the close drop out.
    def samples(days)
      days.filter_map do |day|
        end_of_day = day.date.in_time_zone(zone).end_of_day

        if end_of_day <= charted_until
          [day, end_of_day]
        elsif day.date <= charted_until.to_date
          [day, charted_until]
        end
      end
    end

    def working_days_after(days, date)
      days.count { it.working && it.date > date }
    end

    # The part of +day+ lying after +from+, as a fraction of a whole one. It is zero at a day's
    # close, which is where every sample sits but the two that can fall inside a day.
    def part_of_day_after(day, from)
      return 0.0 unless day.working

      (from.end_of_day - from) / 1.day.to_i
    end

    def days_until_finish(from)
      days.select { it.date >= from.to_date }
    end

    def days
      @days ||= Day.from_range(from: charted_from.to_date, to: finish.to_date).to_a
    end
  end
end

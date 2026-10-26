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

# The Burndown class is responsible for providing the data for what the chart draws:
# three series of Points, each a value at an instant, and the non working days.
#
# - +remaining+ -- the story points still open, summed from the work package journals at every
#   tick between the sprint's start and now.
# - +guideline+ -- the constant reduction the sprint was planned with, declining from what was
#   open at the start to zero on the planned finish date. Time passing does not move it, and a
#   sprint that finished early leaves it stopped above zero rather than redrawn steeper.
# - +projection+ -- the same decline to planned finish date taken up from where remaining leaves off,
#   drawn only while the sprint can still meet that date.
# - +non_working_intervals+ -- date ranges as opposed to Points like the actual series. They are a fact
#   about the calendar rather than a measurement, so they carry no values and the chart paints them behind
#   the series.
#
# Which stretch of time is charted, at what resolution, and which of it is non working is
# ChartWindow's: see there for the instants that decide the shape, and for the viewer's zone.
# +planned_finish+ is the one the guideline and the projection are spent against, whatever the
# sprint actually did -- it sets their slope rather than where they necessarily end.
module Sprints
  class Burndown
    def initialize(sprint:, project:, user: User.current)
      @sprint = sprint
      @project = project
      @user = user
    end

    # The story points still open, sampled up to now.
    def remaining
      @remaining ||= series.sums(open_sprint_journals, :story_points)
    end

    # The constant reduction the sprint was planned with, pinned to what it started with and
    # to the date it was planned to finish, however the sprint actually went. The first sample is
    # taken at the sprint's start, so it is what the sprint began with.
    def guideline
      return [] if remaining.empty?

      @guideline ||= decline_from(remaining.first)
    end

    # Where the current pace would land, drawn only while the sprint can still meet its date.
    def projection
      return [] unless projecting?

      @projection ||= decline_from(remaining.last)
    end

    delegate :step, :too_long_to_chart?, :non_working_intervals, :charted_range, to: :window

    private

    attr_reader :sprint, :project, :user

    delegate :charted_from, :charted_until, :planned_finish, :zone, to: :window, private: true

    def window
      @window ||= ChartWindow.new(sprint, zone: user.time_zone)
    end

    def series
      @series ||= ChartSeries.new(window:, user:)
    end

    def open_sprint_journals
      Journal::WorkPackageJournal.where(project_id: project.id,
                                        sprint_id: sprint.id,
                                        status_id: project.statuses_considered_open)
    end

    def projecting?
      sprint.started_at? && !sprint.completed_at? && remaining.any? &&
        remaining.last.at < planned_finish
    end

    # One straight line, measured in working days rather than in clock time: +drop+ is what a whole
    # day takes, and every point is that slope applied to the distance still to run.
    # Non working days are no distance at all, which is what leaves them flat.
    # Only two points can land inside a day -- the one the series opens on (sprint start or end of remaining) and,
    # where the chart closes before the plan does, the one it closes on.
    def decline_from(origin)
      origin_from = origin.at.in_time_zone(zone)
      days = days_until_planned_finish(origin_from)

      return [origin] if days.none?(&:working)

      drop = origin.value / still_ahead(days, days.first, origin_from)

      points = decline_samples(days).map do |day, at|
        ChartPoint.new(at:, value: drop * still_ahead(days, day, at))
      end

      points.prepend(origin)
    end

    # What the plan has left to spend after +from+, which falls inside +day+. Taken at the
    # origin it is the whole capacity, and at the last sample it is nothing.
    def still_ahead(days, day, from)
      working_days_after(days, day.date) + part_of_day_after(day, from)
    end

    # Each day paired with the last moment the series has a value in it: the day's close, or where
    # the chart closes when that comes first. Days lying wholly beyond the close drop out.
    def decline_samples(days)
      days.filter_map do |day|
        end_of_day = day.date.in_time_zone(zone).end_of_day

        if end_of_day <= charted_until
          [day, end_of_day]
        elsif day.date <= charted_until.to_date
          [day, charted_until]
        end
      end
    end

    # The number of working days the plan still has after +date+.
    def working_days_after(days, date)
      days.count { it.working && it.date > date }
    end

    # The part of +day+ lying after +from+, as a fraction of a whole one. It is zero at a day's
    # close, which is where every sample sits but the two that can fall inside a day: the one the
    # series opens on and, where the chart closes before the plan does, the one it closes on.
    def part_of_day_after(day, from)
      return 0.0 unless day.working

      (from.end_of_day - from) / 1.day.to_i
    end

    def days_until_planned_finish(from)
      planned_days.select { it.date >= from.to_date }
    end

    def planned_days
      @planned_days ||= Day.from_range(from: charted_from.to_date, to: planned_finish.to_date).to_a
    end
  end
end

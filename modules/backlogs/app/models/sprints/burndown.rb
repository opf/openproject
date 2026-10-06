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
# Four time instants decide the shape, and none of them replace one another:
#
# - +charted_from+ -- where the chart opens: the moment the sprint was started, or the opening
#   of its planned start date while it has not been.
# - +measured_until+ -- how far the remaining series is sampled - where measuring stops and
#   projecting begins. The current time for a running sprint, the time it finished for a finished
#   one, and nothing at all for one that has yet to begin.
# - +planned_finish+ -- the date the guideline and the projection are spent against, whatever the
#   sprint actually did; overrunning does not move it. It is what sets their slope rather than
#   where they necessarily end.
# - +charted_until+ -- where the sprint got to (for a completed sprint) or is planned to go to
#   (for a running sprint). If the sprint is running longer than planned, there is no plan any more
#   and the current time is used instead.
#
# The span between +charted_from+ and +charted_until+ sets the resolution -- hourly while that is
# small enough to render, daily beyond it, nothing at all beyond a year.
#
# The viewer's time zone is settled here and handed down to Timeframe and Ticks. Everything below
# either works in absolute instants or is told which zone to use, so that the days these series
# are sampled and declined over start and end where the person reading the chart expects.
module Sprints
  class Burndown
    Point = Data.define(:at, :value)

    # Beyond this an hourly series says more about rendering cost than about progress.
    HOURLY_STEP_LIMIT = 31.days

    # Beyond this a sprint says nothing a reader can act on, and an hourly series over it would
    # not render at all.
    CHARTABLE_SPAN = 1.year

    def initialize(sprint:, project:, user: User.current)
      @sprint = sprint
      @project = project
      @user = user
    end

    # The story points still open, sampled up to now.
    def remaining
      return [] if too_long_to_chart?

      @remaining ||= begin
        sums = story_points_per_tick
        ticks.map { Point.new(at: it, value: (sums[it.to_i] || 0).to_f) }
      end
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

    def non_working_intervals
      return [] if too_long_to_chart?

      @non_working_intervals ||= Day.non_working_intervals(from: charted_from.to_date, to: charted_until.to_date)
    end

    def step
      charted_span > HOURLY_STEP_LIMIT ? :day : :hour
    end

    # Sprints::Burndown draws nothing rather than trying.
    def too_long_to_chart?
      charted_span > CHARTABLE_SPAN
    end

    private

    attr_reader :sprint, :project, :user

    # Named for the sprint rather than for the chart, so they come through as they are.
    delegate :planned_finish, :measured_until, to: :timeframe, private: true

    # The viewer's zone governs the whole chart: it decides where the days the series are sampled
    # and declined over begin and end, so it is settled here and nothing below reaches for another.
    def timeframe
      @timeframe ||= Timeframe.new(sprint, zone:)
    end

    def zone
      user.time_zone
    end

    def ticks
      return [] if measured_until.nil?

      @ticks ||= WorkPackages::JournalTimeline::Ticks.build(from: charted_from,
                                                            to: measured_until,
                                                            step:,
                                                            zone:)
    end

    def charted_from
      timeframe.effective_start
    end

    def charted_until
      timeframe.effective_finish
    end

    # How far the chart reaches, which both of its limits are stated against. Whole days, because
    # that is the resolution both are set at.
    def charted_span
      (charted_until.to_date - charted_from.to_date).to_i.days
    end

    def story_points_per_tick
      timeline(ticks).group(:tick).sum(:story_points).transform_keys(&:to_i)
    end

    def timeline(instants)
      WorkPackages::JournalTimeline.new(open_sprint_journals, ticks: instants, user:).relation
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
    # day takes, and every point is that slope applied to the distance still to run. Non working
    # days are no distance at all, which is what leaves them flat, and only two points can land
    # inside a day -- the one the series opens on (print start or end of remaining) and,
    # where the chart closes before the plan does, the one it closes on.
    def decline_from(origin)
      origin_from = origin.at.in_time_zone(zone)
      days = days_until_planned_finish(origin_from)

      return [origin] if days.none?(&:working)

      drop = origin.value / still_ahead(days, days.first, origin_from)

      points = decline_samples(days).map do |day, at|
        Point.new(at:, value: drop * still_ahead(days, day, at))
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

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
#   open at the start to zero on the planned finish date. Time passing does not move it.
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
# - +planned_finish+ -- where the guideline and the projection have to arrive, whatever the
#   sprint actually did; overrunning does not move it.
# - +charted_until+ -- where the chart closes: the later of the plan and where the sprint got
#   to. The two divert only for a sprint that finished early, whose guideline still has to reach
#   the date it was declining to.
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

    # Where the chart begins.
    def charted_from
      timeframe.effective_start
    end

    # Where the chart ends: the later of where the sprint got to and where it was planned to end.
    # The plan is what the later of the two is for -- a sprint finished early still has to reach
    # the date its guideline declines to.
    def charted_until
      @charted_until ||= [timeframe.effective_finish, planned_finish].max
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

    # Spends the value across the working days left, leaving non working days flat. A series
    # beginning partway through a day only has the rest of that day, so it takes a proportionate
    # share of the value and the whole days after it each carry more to still reach zero on time.
    def decline_from(origin)
      from = origin.at.in_time_zone(zone)
      days = days_until_planned_finish(from)
      shares = days.map { available_share(it, from) }

      return [origin] if shares.sum.zero?

      days.each_with_object([origin]).with_index do |(day, points), index|
        points << declined_point(origin, day, share_ahead(shares, index))
      end
    end

    # The portion of the whole still to come after +index+. Reading it forwards rather than
    # subtracting what is behind leaves the last day an empty slice, so the series lands on zero.
    def share_ahead(shares, index)
      shares[(index + 1)..].sum / shares.sum
    end

    def declined_point(origin, day, ahead)
      Point.new(at: day.date.in_time_zone(zone).end_of_day, value: origin.value * ahead)
    end

    # How much of +day+ is left to the series, as a fraction of a whole day.
    def available_share(day, from)
      return 0.0 unless day.working
      return 1.0 unless day.date == from.to_date

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

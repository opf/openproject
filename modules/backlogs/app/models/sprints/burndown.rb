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

# The three series a sprint's burndown chart draws, each a list of [time, value] points.
module Sprints
  class Burndown
    Point = Data.define(:at, :value)

    # Beyond this many days an hourly series says more about rendering cost than about progress.
    HOURLY_STEP_LIMIT = 31

    def initialize(sprint:, project:, user: User.current)
      @sprint = sprint
      @project = project
      @user = user
    end

    # A sprint running longer than a year says nothing a reader can act on, and an hourly
    # series over it would not render. Sprints::Burndown draws nothing rather than trying.
    def too_long_to_chart?
      charted_until > timeframe.effective_start.to_date + 1.year
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

      @non_working_intervals ||= Day.non_working_intervals(from: timeframe.effective_start.to_date, to: charted_until)
    end

    def step
      (timeframe.effective_start.to_date..charted_until).count > HOURLY_STEP_LIMIT ? :day : :hour
    end

    private

    attr_reader :sprint, :project, :user

    def timeframe
      @timeframe ||= Timeframe.new(sprint)
    end

    def zone
      user.time_zone
    end

    def ticks
      @ticks ||= WorkPackages::JournalTimeline::Ticks.build(from: timeframe.effective_start,
                                                            to: timeframe.observed_until,
                                                            step:, zone:)
    end

    def charted_until
      [timeframe.effective_finish, timeframe.planned_finish].max.to_date
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
        remaining.last.at < timeframe.planned_finish
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
      @planned_days ||= Day.from_range(from: timeframe.effective_start.in_time_zone(zone).to_date,
                                       to: timeframe.planned_finish.to_date).to_a
    end
  end
end

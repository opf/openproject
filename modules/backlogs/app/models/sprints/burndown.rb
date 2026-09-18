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
      charted_until > reference_dates.start.to_date + 1.year
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
    # to the date it was planned to finish, however the sprint actually went.
    def guideline
      return [] if too_long_to_chart?

      @guideline ||= decline_from(Point.new(at: reference_dates.start, value: initial_story_points))
    end

    # Where the current pace would land, drawn only while the sprint can still meet its date.
    def projection
      return [] unless projecting?

      @projection ||= decline_from(remaining.last)
    end

    def non_working_intervals
      return [] if too_long_to_chart?

      @non_working_intervals ||= Day.non_working_intervals(from: reference_dates.start.to_date, to: charted_until)
    end

    def story_points?
      open_sprint_journals.where.not(story_points: nil).exists?
    end

    # Series are sampled at period ends, so a tick reads correctly only once presentation knows
    # which period it closes: an hour end names the hour it opens, a day end names its own date.
    def step
      (reference_dates.start.to_date..charted_until).count > HOURLY_STEP_LIMIT ? :day : :hour
    end

    private

    attr_reader :sprint, :project, :user

    def reference_dates
      @reference_dates ||= ReferenceDates.new(sprint)
    end

    def zone
      user.time_zone
    end

    def ticks
      @ticks ||= WorkPackages::JournalTimeline::Ticks.build(from: reference_dates.start,
                                                            to: [Time.zone.now, reference_dates.finish].min,
                                                            step:, zone:)
    end

    def charted_until
      [reference_dates.finish, reference_dates.scheduled_finish].max.to_date
    end

    def story_points_per_tick
      timeline(ticks).group(:tick).sum(:story_points).transform_keys(&:to_i)
    end

    def initial_story_points
      timeline([reference_dates.start]).sum(:story_points).to_f
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
        remaining.last.at < reference_dates.scheduled_finish
    end

    # Spends the value evenly across the working days left, leaving non working days flat.
    def decline_from(origin)
      days = days_until_scheduled_finish(origin.at)
      working_days = days.count(&:working)

      return [origin] if working_days.zero?

      decrement = origin.value / working_days
      elapsed = 0

      days.each_with_object([origin]) do |day, points|
        elapsed += 1 if day.working
        points << declined_point(origin, day, decrement * elapsed)
      end
    end

    def days_until_scheduled_finish(from)
      Day.from_range(from: from.to_date, to: reference_dates.scheduled_finish.to_date)
    end

    def declined_point(origin, day, spent)
      Point.new(at: day.date.in_time_zone(zone).end_of_day, value: [origin.value - spent, 0.0].max)
    end
  end
end

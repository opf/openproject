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
# - +remaining+ -- the story points or estimated hours still open, summed from the work package journals
#   at every tick between the sprint's start and now. Without an estimation unit, the open work packages are counted.
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

    def remaining
      @remaining ||= series.estimates(open_sprint_journals, project)
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

    def anything_to_chart? = remaining.any? { !it.value.zero? }

    delegate :step, :too_long_to_chart?, :non_working_intervals, :charted_range, to: :window

    private

    attr_reader :sprint, :project, :user

    delegate :planned_finish, to: :window, private: true

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

    def decline_from(origin)
      line.from(origin, to: 0)
    end

    def line
      @line ||= WorkingDayLine.new(window:, finish: planned_finish)
    end
  end
end

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
  class Burnup
    def initialize(sprint:, project:, user: User.current)
      @sprint = sprint
      @project = project
      @user = user
    end

    def scope
      @scope ||= series.estimates(sprint_journals, project)
    end

    def completed
      @completed ||= series.estimates(sprint_journals.where(status_id: project.statuses_considered_closed), project)
    end

    def scope_projection
      return [] unless projecting?

      @scope_projection ||= line.from(scope.last, to: scope.last.value)
    end

    # A constant rise from what was completed at the start to the scope the chart ends
    # on, spent over the working days up to where the chart closes. Unlike the burndown, it follows
    # the sprint: a changed scope moves where it ends.
    def guideline
      return [] if completed.empty?

      @guideline ||= line.from(completed.first, to: scope.last.value)
    end

    def anything_to_chart? = scope.any? { !it.value.zero? }

    delegate :step, :too_long_to_chart?, :non_working_intervals, :charted_range, to: :window

    private

    attr_reader :sprint, :project, :user

    delegate :charted_until, :planned_finish, to: :window, private: true

    def window
      @window ||= ChartWindow.new(sprint, zone: user.time_zone)
    end

    def series
      @series ||= ChartSeries.new(window:, user:)
    end

    def sprint_journals
      Journal::WorkPackageJournal.where(project_id: project.id, sprint_id: sprint.id)
    end

    def line
      @line ||= WorkingDayLine.new(window:, finish: charted_until)
    end

    def projecting?
      sprint.started_at? && !sprint.completed_at? && scope.any? && scope.last.at < planned_finish
    end
  end
end

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

# How much work the project took on over a sprint's window and how much of it was finished, as
# two series of ChartPoints counted from the work package journals at every tick the window
# samples. The work packages in scope are those of the whole project, over a span reaching back
# across the sprints preceding this one -- far enough for a trend to be read rather than a single
# sprint's worth of noise.
#
# - +created+ -- every work package the project held at that tick, whatever its status.
# - +resolved+ -- those of them in a status the project counts as closed, according to the project's backlogs settings.
#
# Both series state what happened within the time span (window) rather than the absolute numbers of work packages.
# A time span that opened with a hundred work packages starts at zero like any other. A time span that
# loses more work packages than it gains therefore ends below zero, as does one that reopens
# more than it closes.
#
# Both are counted at the same ticks.
module Sprints
  class CreatedResolved
    PRECEDING_SPRINT_COUNT = 6

    def initialize(sprint:, project:, user: User.current)
      @sprint = sprint
      @project = project
      @user = user
    end

    def created
      @created ||= rebased(series.counts(project_journals))
    end

    def resolved
      @resolved ||= rebased(series.counts(project_journals.where(status_id: project.statuses_considered_closed)))
    end

    def anything_to_chart? = [created, resolved].any? { |points| points.any? { !it.value.zero? } }

    delegate :step, :too_long_to_chart?, :charted_range, to: :window

    private

    attr_reader :sprint, :project, :user

    def window
      @window ||= ChartWindow.spanning(charted_sprints, zone: user.time_zone)
    end

    def charted_sprints
      preceding = Sprint.for_project(project).visible(user).preceding(sprint, limit: PRECEDING_SPRINT_COUNT)

      [*preceding, sprint]
    end

    def series
      @series ||= ChartSeries.new(window:, user:)
    end

    def rebased(points)
      opening = points.first&.value || 0.0

      points.map { ChartPoint.new(at: it.at, value: it.value - opening) }
    end

    def project_journals
      Journal::WorkPackageJournal.where(project_id: project.id)
    end
  end
end

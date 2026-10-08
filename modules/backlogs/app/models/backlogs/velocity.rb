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

module Backlogs
  class Velocity
    SPRINT_COUNT = 7

    EXECUTION_ORDER = [
      "COALESCE(sprints.started_at, sprints.start_date)",
      "COALESCE(sprints.completed_at, sprints.finish_date)",
      "sprints.id"
    ].freeze

    def initialize(sprint, project)
      @sprint = sprint
      @project = project
    end

    attr_reader :sprint, :project

    def sprints
      @sprints ||= [*preceding_sprints.reverse, sprint]
    end

    def committed
      @committed ||= breakdowns.map { it.initially_planned.story_points.to_f }
    end

    def completed
      @completed ||= breakdowns.map { it.completed.story_points.to_f }
    end

    def velocity = completed.last

    def average = completed.sum.fdiv(completed.size)

    private

    def preceding_sprints
      execution_key = EXECUTION_ORDER.join(", ")

      Sprint
        .for_project(project)
        .where.not(status: :in_planning)
        .where("(#{execution_key}) < (SELECT #{execution_key} FROM sprints WHERE sprints.id = ?)", sprint.id)
        .order(Arel.sql(EXECUTION_ORDER.map { "#{it} DESC" }.join(", ")))
        .limit(SPRINT_COUNT - 1)
        .to_a
    end

    def breakdowns
      @breakdowns ||= sprints.map { SprintWorkPackageBreakdown.new(sprint: it, project:) }
    end
  end
end

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
  class Velocity
    SPRINT_COUNT = 7

    def initialize(sprint, project)
      @sprint = sprint
      @project = project
    end

    attr_reader :sprint, :project

    def sprints
      @sprints ||= [*preceding_sprints, sprint]
    end

    def committed
      @committed ||= breakdowns.map { metric_value(it.initially_planned) }
    end

    def completed
      @completed ||= breakdowns.map { metric_value(it.completed) }
    end

    def velocity = completed.last

    def average
      preceding = completed[...-1]
      preceding.sum.fdiv(preceding.size) if preceding.any?
    end

    def preceding_sprints
      @preceding_sprints ||= Sprint.for_project(project)
                                   .visible
                                   .where("COALESCE(sprints.completed_at, sprints.finish_date) IS NOT NULL")
                                   .preceding(sprint, limit: SPRINT_COUNT - 1)
    end

    private

    def breakdowns
      @breakdowns ||= sprints.map { Sprints::WorkPackageBreakdown.new(sprint: it, project:) }
    end

    def metric_value(block)
      if project.estimation_unit_story_points?
        block.story_points
      elsif project.estimation_unit_time?
        block.estimated_hours
      else
        block.work_package_count
      end
    end
  end
end

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
  module SprintReports
    module Widgets
      class VelocityChart < Grids::WidgetComponent
        include Backlogs::CommonHelper

        param :sprint
        param :project

        def title
          t(".title")
        end

        def wrapper_arguments
          { full_width: true }
        end

        def render?
          !sprint.in_planning? &&
            sprint.date_range_set? &&
            !project.allow_multiple_active_sprints? &&
            user_allowed?(:view_sprints)
        end

        def chart_data
          {
            labels: velocity.sprints.map(&:name),
            datasets:,
            average: velocity.average.round(1),
            yAxisTitle: t(".y_axis_title"),
            summary: t(".summary", count: velocity.sprints.size, average: formatted_average),
            sprintColumnTitle: Sprint.model_name.human
          }.to_json
        end

        def velocity_label
          t(".velocity", sprint: sprint.name)
        end

        def average_label
          t(".average", count: velocity.sprints.size)
        end

        def formatted_velocity
          story_points(velocity.velocity.round)
        end

        def formatted_average
          story_points(helpers.number_with_precision(velocity.average, precision: 1, strip_insignificant_zeros: true))
        end

        private

        def velocity
          @velocity ||= Backlogs::Velocity.new(sprint, project)
        end

        def datasets
          [
            { label: t(".committed"), data: velocity.committed.map(&:round) },
            { label: t(".completed"), data: velocity.completed.map(&:round) }
          ]
        end

        def story_points(value)
          t(".story_points", value:)
        end
      end
    end
  end
end

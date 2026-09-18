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
# ++

module Backlogs
  module SprintReports
    module Widgets
      class BurndownChart < Grids::WidgetComponent
        param :sprint
        param :project

        def title
          t("backlogs.show_burndown_chart")
        end

        # Timestamps go out as UTC; the chart renders them in the viewer's zone. They sit at
        # period ends, so the chart needs the step to label them the way a reader expects.
        def chart_data
          {
            step: burndown.step,
            series: series,
            nonWorkingIntervals: non_working_intervals
          }.to_json
        end

        def wrapper_arguments
          { full_width: true }
        end

        private

        def burndown
          return nil unless sprint.date_range_set?

          @burndown ||= ::Sprints::Burndown.new(sprint:, project:)
        end

        def series
          { remaining: burndown.remaining,
            guideline: burndown.guideline,
            projection: burndown.projection }
            .reject { |_, points| points.empty? }
            .map { |id, points| { id:, label: t("backlogs.burndown.series.#{id}"), data: points_for(points) } }
        end

        def points_for(points)
          points.map { { x: it.at.utc.iso8601(3), y: it.value } }
        end

        def non_working_intervals
          burndown.non_working_intervals.map { { from: it.first.iso8601, to: it.last.iso8601 } }
        end
      end
    end
  end
end

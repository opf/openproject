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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Backlogs
  module SprintReports
    module Widgets
      class BurnupChart < Grids::WidgetComponent
        include BurnChartBlankslate

        param :sprint
        param :project

        def title = t(".title")

        def chart_data
          {
            unit:,
            step: burnup.step,
            range: charted_range,
            series: series,
            nonWorkingIntervals: non_working_intervals
          }.to_json
        end

        def wrapper_arguments
          { full_width: true }
        end

        def render?
          sprint.date_range_set? && !project.estimation_unit_none?
        end

        private

        def unit = project.estimation_unit_time? ? :time : :story_points

        delegate :too_long_to_chart?, :anything_to_chart?, to: :burnup, private: true

        def burnup
          @burnup ||= ::Sprints::Burnup.new(sprint:, project:)
        end

        def series
          { completed: burnup.completed,
            scope: burnup.scope,
            projection: burnup.scope_projection,
            guideline: burnup.guideline }
            .reject { |_, points| points.empty? }
            .map { |id, points| { id:, label: t(".series.#{id}"), data: points_for(points) } }
        end

        def points_for(points)
          points.map { { x: it.at.utc.iso8601(3), y: it.value.round(3) } }
        end

        def charted_range
          { from: burnup.charted_range.first.utc.iso8601(3),
            to: burnup.charted_range.last.utc.iso8601(3) }
        end

        def non_working_intervals
          burnup.non_working_intervals.map { { from: it.first.iso8601, to: it.last.iso8601 } }
        end
      end
    end
  end
end

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
      class WorkPackageGraph < Grids::WidgetComponent
        include Backlogs::CommonHelper
        include ChartBlankslate

        Bar = Data.define(:label, :count, :color)

        param :sprint
        param :project
        param :breakdown

        def title
          t(".title")
        end

        def wrapper_arguments
          { full_width: true }
        end

        def render? = sprint.date_range_set? && user_allowed?(:view_sprints)

        def chart_data
          {
            labels: bars.map(&:label),
            data: bars.map(&:count),
            colors: bars.map(&:color),
            summary:,
            statusColumnTitle: WorkPackage.human_attribute_name(:status),
            countColumnTitle: WorkPackage.model_name.human(count: 2)
          }.to_json
        end

        private

        def blankslate_reason
          :no_work if bars.empty?
        end

        # Statuses might have been deleted. If that happened, work packages associated to that
        # status are ignored in the count.
        def bars
          @bars ||= Status.includes(:color)
                          .where(id: breakdown.status_counts.keys)
                          .map { Bar.new(label: it.name, count: breakdown.status_counts[it.id], color: it.color&.hexcode) }
        end

        # The chart is frozen once the sprint is completed, so the summary names that moment
        # rather than claiming to describe the sprint as it stands.
        def summary
          t(".summary.#{sprint.completed_at? ? 'completed' : 'current'}",
            description: bars.map { "#{it.count} #{it.label}" }.join("; "))
        end
      end
    end
  end
end

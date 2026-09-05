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
      class WorkPackageGraph < Grids::WidgetComponent
        include Backlogs::CommonHelper

        param :sprint
        param :project

        def title
          t(".title")
        end

        def wrapper_arguments
          { full_width: true }
        end

        def render? = user_allowed?(:view_sprints)

        def call
          widget_wrapper do |widget|
            widget.with_body do
              helpers.angular_component_tag(
                "opce-wp-overview-graph",
                "global-scope": false,
                "initial-filters": graph_filters.to_json,
                "show-group-by-options": false
              )
            end
          end
        end

        private

        def graph_filters
          [
            { sprint: { operator: "=", values: [sprint.id] } },
            { project: { operator: "=", values: [project.id] } }
          ]
        end
      end
    end
  end
end

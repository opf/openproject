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

module TeamPlanner
  class RowComponent < ::RowComponent
    def query
      model
    end

    delegate :project, to: :query

    def name
      link_to query.name, project_team_planner_path(project, query.id)
    end

    def created_at
      helpers.format_time(query.created_at)
    end

    def assignees
      query
        .filters
        .detect { |filter| filter.name == :assigned_to_id }
        .then { |filter| filter ? filter.valid_values!.count : 0 }
    end

    def button_links
      [delete_link].compact
    end

    def delete_link
      if table.current_user.allowed_in_project?(:manage_team_planner, project)
        link_to(
          "",
          project_team_planner_path(project, query.id),
          class: "spot-link icon icon-delete",
          method: :delete,
          data: {
            confirm: I18n.t(:text_are_you_sure),
            "test-selector": "team-planner-remove-#{query.id}"
          },
          title: t(:button_delete)
        )
      end
    end
  end
end

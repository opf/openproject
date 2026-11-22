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

module Overviews
  class ProjectDashboardsTableComponent < OpPrimer::BorderBoxTableComponent
    columns :name, :status, :projects
    main_column :name
    mobile_labels :status, :projects

    options :project, :dashboard_type, :filters, :current_user

    def headers
      [
        [:name, { caption: t(:label_name) }],
        [:status, { caption: t(:label_status) }],
        [:projects, { caption: t(:label_project_plural) }]
      ]
    end

    def row_class = ProjectDashboardRowComponent

    def has_actions? = true

    def reorderable? = dashboard_type.nil? && filters.nil? && rows.many?(&:assigned)

    def mobile_title = t("overviews.dashboards.title")

    def blank_title = t(:label_no_data)

    def can_manage_standard? = current_user.allowed_globally?(:manage_standard_dashboards)

    def projects_count(dashboard)
      projects_counts.fetch(dashboard.id, 0)
    end

    def container_id = "project-dashboards-table"

    def container_data
      return {} unless reorderable?

      {
        controller: "sortable-lists sortable-lists--list",
        sortable_lists_move_url_template_value: project_move_dashboard_tab_path(project, "__id__").sub("__id__", "{id}"),
        sortable_lists_sortable_lists__list_outlet: "##{container_id}",
        sortable_lists_sortable_lists__item_outlet: "##{container_id} [data-controller~='sortable-lists--item']",
        sortable_lists__list_type_value: DashboardTabs::SORTABLE_LIST_TYPE,
        sortable_lists__list_accepted_type_value: DashboardTabs::SORTABLE_LIST_TYPE,
        sortable_lists__list_name_value: mobile_title,
        sortable_lists__list_rows_container_element: ":scope > .#{rows_container_class}"
      }
    end

    private

    def projects_counts
      @projects_counts ||= DashboardPageAssignment.where(
        grid_id: rows.select(&:standard?).map { |entry| entry.dashboard.id },
        active: true,
        project: Project.active
      ).group(:grid_id).count
    end
  end
end

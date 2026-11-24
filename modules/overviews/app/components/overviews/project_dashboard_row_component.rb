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
  class ProjectDashboardRowComponent < OpPrimer::BorderBoxRowComponent
    include SortableLists::MoveMenu

    alias_method :entry, :model
    delegate :project, :dashboard_type, :filters, to: :table
    delegate :dashboard, :display_name, to: :entry

    def row_css_id = "project-dashboard-#{entry.key}"

    def row_data
      data = { dashboard_tab_key: entry.key }
      return data unless reorderable?

      data.merge(
        controller: "sortable-lists--item",
        sortable_lists__item_target: "preview",
        sortable_lists__item_id_value: entry.key,
        sortable_lists__item_type_value: DashboardTabs::SORTABLE_LIST_TYPE,
        sortable_lists__item_label_value: display_name
      )
    end

    def name
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) { drag_handle } if reorderable?
        flex.with_column { dashboard_name }

        if entry.standard?
          flex.with_column(ml: 2) do
            render(Primer::Beta::Label.new(scheme: :primary)) { t("overviews.dashboards.types.standard") }
          end
        end
      end
    end

    def status
      render(
        Primer::Alpha::ToggleSwitch.new(
          src: toggle_path,
          checked: entry.active,
          enabled: !entry.required?,
          turbo: true,
          size: :small,
          status_label_position: :start,
          on_label: (t("overviews.dashboards.all_projects") if entry.required?),
          aria: { label: t("overviews.dashboards.toggle", name: display_name) },
          classes: "op-primer-adjustments__toggle-switch--hidden-loading-indicator",
          data: { test_selector: "toggle-dashboard-#{entry.key}" }
        )
      )
    end

    def projects
      return table.projects_count(dashboard) if entry.standard?

      entry.active ? 1 : 0
    end

    def button_links
      return [] unless manageable? || reorderable?

      [action_menu]
    end

    private

    def reorderable? = entry.assigned && table.reorderable?

    def toggle_path
      return if entry.required?

      if entry.original?
        project_toggle_original_dashboard_path(project, dashboard_type:, filters:)
      else
        toggle_project_dashboard_page_path(project, dashboard, dashboard_type:, filters:)
      end
    end

    def dashboard_name
      if (path = edit_path)
        render(Primer::Beta::Link.new(href: path, underline: false, font_weight: :bold)) { display_name }
      else
        render(Primer::Beta::Text.new(font_weight: :bold)) { display_name }
      end
    end

    def edit_path
      return standard_edit_path if entry.standard?
      return unless entry.active

      if entry.original?
        project_edit_settings_original_dashboard_path(project)
      else
        project_edit_settings_dashboard_page_path(project, dashboard)
      end
    end

    def standard_edit_path
      edit_admin_dashboard_page_path(dashboard) if table.can_manage_standard?
    end

    def drag_handle
      render(Primer::OpenProject::DragHandle.new(data: { sortable_lists__item_target: "handle" }))
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: :"kebab-horizontal", scheme: :invisible, "aria-label": t(:label_actions))
        rename_item(menu) if manageable?
        with_move_submenu(menu) if reorderable?
        delete_item(menu) if manageable? && !entry.original?
      end
    end

    def manageable? = dashboard.present? && !entry.standard?

    def rename_item(menu)
      path = if entry.original?
               project_rename_original_dashboard_dialog_path(project, from_settings: "1")
             else
               rename_dialog_project_dashboard_page_path(project, dashboard, from_settings: "1")
             end
      menu.with_item(label: t(:button_rename), tag: :a, href: path,
                     content_arguments: { data: { controller: "async-dialog" } }) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def delete_item(menu)
      menu.with_item(label: t(:button_delete), tag: :a, scheme: :danger,
                     href: deletion_dialog_project_dashboard_page_path(project, dashboard, from_settings: "1"),
                     content_arguments: { data: { controller: "async-dialog" } }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end

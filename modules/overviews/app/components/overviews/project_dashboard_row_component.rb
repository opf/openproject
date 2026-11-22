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
    alias_method :entry, :model
    delegate :project, :dashboard_type, to: :table
    delegate :dashboard, to: :entry

    def row_data = { dashboard_tab_key: entry.key }

    def name
      flex_layout(align_items: :center) do |flex|
        flex.with_column { dashboard_name }

        if entry.standard?
          flex.with_column(ml: 2) do
            render(Primer::Beta::Label.new(scheme: :primary)) { t("overviews.dashboards.types.standard") }
          end
        end
      end
    end

    def status
      render(Primer::Beta::Text.new(color: :subtle)) do
        t(entry.active ? "overviews.dashboards.active" : "overviews.dashboards.inactive")
      end
    end

    def button_links
      return [] unless editable? || !entry.active || reorderable?

      [action_menu]
    end

    private

    def dashboard_name
      if entry.active
        render(Primer::Beta::Link.new(href: dashboard_path, underline: false, font_weight: :bold)) { display_name }
      else
        render(Primer::Beta::Text.new(font_weight: :bold)) { display_name }
      end
    end

    def display_name
      entry.original? ? (dashboard&.display_name || t("overviews.label_dashboard")) : dashboard.name
    end

    def dashboard_path
      entry.original? ? dashboard_project_overview_path(project) : project_dashboard_page_path(project, dashboard)
    end

    def editable? = entry.active && !entry.original? && !entry.standard?

    def reorderable? = table.reorderable? && table.rows.size > 1

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: :"kebab-horizontal", scheme: :invisible, "aria-label": t(:label_actions))

        with_item_group(menu) { dashboard_action(menu) }
        with_item_group(menu) { move_actions(menu) } if reorderable?
      end
    end

    def dashboard_action(menu)
      if editable?
        menu.with_item(label: t(:button_edit),
                       tag: :a,
                       href: project_edit_settings_dashboard_page_path(project, dashboard)) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      elsif !entry.active
        menu.with_item(label: t("overviews.dashboards.activate"),
                       tag: :button,
                       href: activate_path,
                       form_arguments: { method: :patch }) do |item|
          item.with_leading_visual_icon(icon: :eye)
        end
      end
    end

    def move_actions(menu)
      move_item(menu, "up", t(:label_sort_higher), :"chevron-up") unless entry == table.rows.first
      move_item(menu, "down", t(:label_sort_lower), :"chevron-down") unless entry == table.rows.last
    end

    def activate_path
      if entry.original?
        project_activate_original_dashboard_path(project, dashboard_type:)
      else
        activate_project_dashboard_page_path(project, dashboard, dashboard_type:)
      end
    end

    def move_item(menu, direction, label, icon)
      menu.with_item(label:, tag: :button,
                     href: project_move_dashboard_tab_path(project, entry.key),
                     form_arguments: { method: :patch, inputs: [{ name: "direction", value: direction }] }) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end
  end
end

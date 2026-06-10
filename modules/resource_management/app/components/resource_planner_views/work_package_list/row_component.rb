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

module ResourcePlannerViews::WorkPackageList
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    alias_method :work_package, :model

    # Must match the container's accepted type in ContentComponent so the
    # drag-and-drop controller only accepts rows from this list.
    DRAGGABLE_TYPE = "resource-work-package"

    # `row_data` runs while the parent table builds the row, before this
    # component enters the render pipeline, so `helpers` is unavailable — hence
    # the direct route-helpers call.
    def row_data
      return {} unless manual?

      {
        draggable_type: DRAGGABLE_TYPE,
        draggable_id: work_package.id,
        drop_url: Rails.application.routes.url_helpers.reorder_work_package_project_resource_planner_view_path(
          table.project, table.resource_planner, table.view, work_package_id: work_package.id
        )
      }
    end

    def row_css_id
      "resource-work-package-row-#{work_package.id}" if manual?
    end

    # Manual lists prepend a drag handle — the drag-and-drop controller only
    # starts a drag from a `.DragHandle`.
    def subject
      return subject_content unless manual?

      flex_layout(align_items: :center) do |row|
        row.with_column(mr: 2) { render(Primer::OpenProject::DragHandle.new) }
        row.with_column(flex: 1) { subject_content }
      end
    end

    def subject_content
      safe_join(
        [
          render(WorkPackages::InfoLineComponent.new(work_package:, show_status: true)),
          render(
            Primer::Beta::Link.new(
              href: helpers.url_for(controller: "/work_packages", action: "show", id: work_package),
              font_weight: :bold,
              underline: false
            )
          ) { work_package.subject }
        ]
      )
    end

    def priority
      return if work_package.priority.blank?

      render(
        Primer::Beta::Text.new(
          tag: :span,
          classes: "__hl_inline_priority_#{work_package.priority.id} __hl_inline__small_dot"
        )
      ) { work_package.priority.name }
    end

    def dates
      return if work_package.start_date.blank? && work_package.due_date.blank?

      render(WorkPackages::HighlightedDateComponent.new(work_package:))
    end

    def allocation
      render(Primer::Beta::Text.new(color: :muted)) { allocation_placeholder }
    end

    def allocated_members
      render(Primer::Beta::Text.new(color: :muted)) { allocation_placeholder }
    end

    def button_links
      [context_menu]
    end

    private

    def allocation_placeholder
      I18n.t("resource_management.work_package_list.allocation_placeholder")
    end

    def context_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": t("resource_management.work_package_list.context_menu.label"),
                              scheme: :invisible)

        see_allocation_item(menu)
        edit_total_work_item(menu)
        add_user_group_item(menu)

        if manual?
          move_item(menu)
          remove_item(menu)
        else
          add_filter_criteria_item(menu)
        end
      end
    end

    def see_allocation_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.see_allocation"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :hourglass)
      end
    end

    def edit_total_work_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.edit_total_work"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def add_user_group_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.add_user_group"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :"person-add")
      end
    end

    def add_filter_criteria_item(menu)
      menu.with_item(label: t("resource_management.work_package_list.context_menu.add_filter_criteria"),
                     disabled: true) do |item|
        item.with_leading_visual_icon(icon: :plus)
      end
    end

    def move_item(menu)
      menu.with_sub_menu_item(label: t("resource_management.work_package_list.context_menu.move")) do |submenu|
        submenu.with_leading_visual_icon(icon: :"arrow-right")

        ns = "resource_management.work_package_list.context_menu"
        unless first?
          move_action(submenu, direction: "top", label: t("#{ns}.move_to_top"), icon: "move-to-top")
          move_action(submenu, direction: "up", label: t("#{ns}.move_up"), icon: "chevron-up")
        end
        unless last?
          move_action(submenu, direction: "down", label: t("#{ns}.move_down"), icon: "chevron-down")
          move_action(submenu, direction: "bottom", label: t("#{ns}.move_to_bottom"), icon: "move-to-bottom")
        end
      end
    end

    def move_action(submenu, direction:, label:, icon:)
      submenu.with_item(
        label:,
        href: helpers.move_work_package_project_resource_planner_view_path(
          table.project, table.resource_planner, table.view, work_package_id: work_package.id, direction:
        ),
        form_arguments: { method: :put }
      ) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def remove_item(menu)
      menu.with_item(
        label: t("resource_management.work_package_list.context_menu.remove"),
        scheme: :danger,
        href: helpers.remove_work_package_project_resource_planner_view_path(
          table.project, table.resource_planner, table.view, work_package_id: work_package.id
        ),
        form_arguments: {
          method: :delete,
          data: { turbo_confirm: t("resource_management.work_package_list.context_menu.remove_confirmation") }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def manual?
      table.manual?
    end

    def position_index
      @position_index ||= table.rows.index { |wp| wp.id == work_package.id }
    end

    def first?
      position_index.zero?
    end

    def last?
      position_index == table.rows.size - 1
    end
  end
end

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

module ResourceAllocations
  class AssignmentRowComponent < ::OpPrimer::BorderBoxRowComponent
    alias_method :allocation, :model

    def resource
      flex_layout(align_items: :center) do |row|
        row.with_column { filter_name_link }
        row.with_column(ml: 2, display: :flex) { criteria_tooltip } unless filter_summary.empty?
      end
    end

    def work_package
      entity = allocation.entity
      return hidden_work_package unless entity.is_a?(WorkPackage) && visible_work_package?(entity)

      render(WorkPackages::InfoLineComponent.new(work_package: entity, show_subject: true, show_status: true))
    end

    def dates
      content = date_range
      return content unless starts_in_past?

      flex_layout(align_items: :center) do |row|
        row.with_column(mr: 1) do
          render(Primer::Beta::Text.new(color: :danger)) { content }
        end
        row.with_column do
          render(Primer::Beta::Octicon.new(
                   icon: :alert,
                   color: :danger,
                   "aria-label": I18n.t("resource_management.staffing.starts_in_past")
                 ))
        end
      end
    end

    def requested_time
      DurationConverter.output(allocation.allocated_hours)
    end

    # The date range can be too wide for a narrow viewport; let it wrap instead of
    # being truncated with an ellipsis like the other non-main columns.
    def cell_classes(column)
      class_names(super, "-no-ellipsis": column == :dates)
    end

    def button_links
      return [] unless can_assign? || can_manage?

      [action_menu]
    end

    private

    def action_menu
      render(Primer::Alpha::ActionMenu.new(size: :small, anchor_align: :end)) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": I18n.t("resource_management.staffing.context_menu_label"),
                              scheme: :invisible)

        assign_item(menu) if can_assign?
        edit_item(menu) if can_manage?
        delete_item(menu) if can_manage?
      end
    end

    def can_assign?
      User.current.allowed_in_project?(:assign_users_to_generic_allocations, table.project)
    end

    def can_manage?
      User.current.allowed_in_project?(:allocate_user_resources, table.project)
    end

    def assign_item(menu)
      menu.with_item(
        label: I18n.t("resource_management.staffing.assign"),
        tag: :a,
        href: helpers.project_staffing_assign_path(table.project, allocation),
        content_arguments: { data: { controller: "async-dialog" } }
      ) do |item|
        item.with_leading_visual_icon(icon: :"person-add")
      end
    end

    def edit_item(menu)
      menu.with_item(
        label: I18n.t(:button_edit),
        tag: :a,
        href: helpers.edit_project_resource_allocation_path(table.project, allocation),
        content_arguments: { data: { controller: "async-dialog" } }
      ) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def delete_item(menu)
      menu.with_item(
        label: I18n.t(:button_delete),
        scheme: :danger,
        href: helpers.project_resource_allocation_path(table.project, allocation),
        form_arguments: {
          method: :delete,
          data: {
            turbo_confirm: I18n.t("resource_management.staffing.delete_confirmation"),
            turbo_stream: true
          }
        }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    def filter_name_link
      render(
        Primer::Beta::Link.new(
          href: helpers.project_staffing_assign_path(table.project, allocation),
          font_weight: :bold,
          underline: false,
          data: { controller: "async-dialog" }
        )
      ) do
        flex_layout(align_items: :center) do |row|
          row.with_column(mr: 2) do
            render(Primer::Beta::Octicon.new(icon: :"person-add", color: :muted, "aria-hidden": true))
          end
          row.with_column { allocation.placeholder_user&.name }
        end
      end
    end

    def filter_summary
      @filter_summary ||= Queries::FilterSummary.new(allocation.placeholder_user&.user_filter)
    end

    def criteria_tooltip
      summary = filter_summary.to_s

      safe_join(
        [
          render(Primer::Beta::Octicon.new(icon: :info, color: :muted, id: criteria_tooltip_id, "aria-label": summary)),
          render(Primer::Alpha::Tooltip.new(for_id: criteria_tooltip_id, type: :description, text: summary, direction: :se))
        ]
      )
    end

    def criteria_tooltip_id
      "staffing-criteria-#{allocation.id}"
    end

    def date_range
      "#{format_date_or_dash(allocation.start_date)} – #{format_date_or_dash(allocation.end_date)}"
    end

    def format_date_or_dash(date)
      date.present? ? helpers.format_date(date) : "—"
    end

    # All listed allocations are unassigned, so a start in the past means the
    # work is overdue to be staffed.
    def starts_in_past?
      allocation.start_date.present? && allocation.start_date < Time.zone.today
    end

    def visible_work_package?(work_package)
      table.visible_work_package_ids.include?(work_package.id)
    end

    def hidden_work_package
      render(Primer::Beta::Text.new(color: :muted)) do
        I18n.t("resource_management.work_package_allocations_dialog.hidden_user")
      end
    end
  end
end

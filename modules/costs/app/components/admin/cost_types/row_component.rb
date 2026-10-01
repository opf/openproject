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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Admin
  module CostTypes
    class RowComponent < ::RowComponent
      delegate :unit, :unit_plural, to: :cost_type

      def cost_type
        model
      end

      def name
        helpers.link_to(cost_type.name, helpers.edit_admin_cost_type_path(cost_type))
      end

      def current_rate
        helpers.to_currency_with_empty(cost_type.rate_at(Date.current))
      end

      def default
        checkmark(cost_type.is_default?, primerized: true)
      end

      def active_projects
        if cost_type.for_all_projects?
          I18n.t("settings.project_attributes.label_for_all_projects")
        else
          count = Project.active.joins(:cost_types_projects)
                         .where(cost_types_projects: { cost_type_id: cost_type.id })
                         .count
          count.zero? ? I18n.t(:label_none) : count
        end
      end

      def deleted_at
        helpers.format_date(cost_type.deleted_at) if cost_type.deleted_at
      end

      def column_css_class(column)
        column == :current_rate ? "currency" : super
      end

      def row_css_id
        "cost_type_#{cost_type.id}"
      end

      def button_links
        table.locked? ? [restore_link] : [lock_link]
      end

      def lock_link
        render(
          Primer::Beta::IconButton.new(
            icon: :lock,
            scheme: :invisible,
            tag: :a,
            href: helpers.admin_cost_type_path(cost_type),
            "aria-label": t(:button_lock),
            tooltip_direction: :w,
            test_selector: "op-admin-cost-type-#{cost_type.id}-lock",
            data: {
              turbo_method: :delete,
              turbo_confirm: t(:text_are_you_sure)
            }
          )
        )
      end

      def restore_link
        render(
          Primer::Beta::IconButton.new(
            icon: :unlock,
            scheme: :invisible,
            tag: :a,
            href: helpers.restore_admin_cost_type_path(cost_type),
            "aria-label": t(:button_unlock),
            tooltip_direction: :w,
            test_selector: "op-admin-cost-type-#{cost_type.id}-restore",
            data: { turbo_method: :patch }
          )
        )
      end
    end
  end
end

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

module Budgets
  module MaterialBudgetItems
    class SubformRowComponent < BudgetItems::SubformRowComponent
      include CostlogHelper

      def units
        primer_text_field(
          name: :units,
          copied_from: true,
          label: MaterialBudgetItem.human_attribute_name(:units),
          value: unitless_currency_number(budget_item.units),
          # Avoid a number field due to chrome bug (OP#32232)
          # but show the appearance of a decimal field on mobile
          inputmode: :decimal,
          placeholder: t(:label_example_placeholder, decimal: unitless_currency_number(1000.50)),
          classes: "budget-item-value",
          trailing_visual: { text: { id: "#{id_prefix}_unit_name", text: unit_name } },
          aria: { describedby: "#{id_prefix}_unit_name" },
          data: {
            request_key: "units",
            action: "keyup->costs--budget-subform#valueChanged"
          }
        )
      end

      def cost_type
        primer_select(
          name: :cost_type_id,
          label: MaterialBudgetItem.human_attribute_name(:cost_type),
          classes: "budget-item-value",
          data: {
            request_key: "cost_type_id",
            action: "change->costs--budget-subform#valueChanged"
          }
        ) do |select|
          cost_types_collection_for_select_options(budget_item.cost_type, project:)
            .each do |label, value|
              select.option label:, value:
            end
        end
      end

      def comments
        primer_text_field(name: :comments, label: MaterialBudgetItem.human_attribute_name(:comments))
      end

      def cost
        inline_cost_edit(cost_value: budget_item.calculated_costs(budget.fixed_date))
      end

      def prefix = "#{new_or_existing}_material_budget_item_attributes[]"
      def id_prefix = "budget_#{new_or_existing}_material_budget_item_attributes_#{id_or_index}"
      def name_prefix = "budget[#{new_or_existing}_material_budget_item_attributes][#{id_or_index}]"

      private

      # Primer::Beta::Truncate renders nothing for blank content, but the row
      # refresh needs the element to write the unit name into.
      def unit_name
        budget_item.cost_type&.unit_plural.presence || "&nbsp;".html_safe
      end
    end
  end
end

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
  module LaborBudgetItems
    class SubformRowComponent < BudgetItems::SubformRowComponent
      def hours
        primer_text_field(
          name: :hours,
          label: LaborBudgetItem.human_attribute_name(:hours),
          inputmode: :decimal,
          placeholder: t(:label_example_placeholder, decimal: unitless_currency_number(1000.50)),
          classes: "budget-item-value",
          data: {
            request_key: "hours",
            action: "keyup->costs--budget-subform#valueChanged"
          }
        )
      end

      def user
        primer_select(
          name: :user_id,
          label: I18n.t(:label_user),
          classes: "budget-item-value",
          data: {
            request_key: "user_id",
            action: "change->costs--budget-subform#valueChanged"
          }
        ) do |select|
          Principal
            .possible_assignee(project)
            .sort
            .map { [it.name, it.id] }
            .each do |label, value|
            select.option(label:, value:)
          end
        end
      end

      def comments
        primer_text_field(name: :comments, label: LaborBudgetItem.human_attribute_name(:comments))
      end

      def cost
        # Keep current budget as hidden field because otherwise they will be overridden
        if templated == false && budget_item.overridden_costs?
          form.hidden_field :amount, index: id_or_index, value: unitless_currency_number(budget_item.amount)
        end

        cost_value = budget_item.amount || budget_item.calculated_costs(budget.fixed_date, budget.project_id)
        render(
          BudgetItems::InlineCostEditComponent.new(
            input_name: "#{name_prefix}[amount]",
            input_id: "#{id_prefix}_amount",
            cost_value:
          )
        )
      end

      def prefix = "#{new_or_existing}_labor_budget_item_attributes[]"
      def id_prefix = "budget_#{new_or_existing}_labor_budget_item_attributes_#{id_or_index}"
      def name_prefix = "budget[#{new_or_existing}_labor_budget_item_attributes][#{id_or_index}]"
    end
  end
end

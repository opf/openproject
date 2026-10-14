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
      include BudgetsHelper

      def hours
        primer_text_field(
          name: :hours,
          copied_from: true,
          label: LaborBudgetItem.human_attribute_name(:hours),
          value: DurationConverter.output(budget_item.hours),
          # Avoid a number field due to chrome bug (OP#32232)
          placeholder: t(:label_example_placeholder, decimal: "2d 10h"),
          classes: "budget-item-value",
          data: {
            controller: "chronic-duration",
            request_key: "hours",
            action: "keyup->costs--budget-subform#valueChanged",
            **DurationConverter.stimulus_data_values("chronic-duration")
          }
        )
      end

      def user
        # The form block is evaluated on the form, so resolve everything first.
        input_id = "#{id_prefix}_user_id"
        inputs = labor_budget_item_user_autocompleter_inputs(
          budget_item, project:, name: "#{name_prefix}[user_id]", id: input_id
        )

        with_form do |f|
          f.autocompleter(
            name: :user_id,
            label: LaborBudgetItem.human_attribute_name(:user),
            visually_hide_label: true,
            autocomplete_options: { component: "opce-user-autocompleter", labelForId: input_id, **inputs }
          )
        end
      end

      def comments
        primer_text_field(name: :comments, label: LaborBudgetItem.human_attribute_name(:comments))
      end

      def cost
        inline_cost_edit(
          cost_value: budget_item.calculated_costs(budget.fixed_date, budget.project_id),
          hint: rate_hint,
          hint_id: "#{id_prefix}_cost_hint"
        )
      end

      def prefix = "#{new_or_existing}_labor_budget_item_attributes[]"
      def id_prefix = "budget_#{new_or_existing}_labor_budget_item_attributes_#{id_or_index}"
      def name_prefix = "budget[#{new_or_existing}_labor_budget_item_attributes][#{id_or_index}]"

      private

      # `nil` renders no hint element at all, a string (possibly empty) renders
      # one the row refresh can write into.
      def rate_hint
        return unless costs_visible?

        labor_budget_item_rate_hint(budget_item, fixed_date: budget.fixed_date, project_id: budget.project_id)
      end
    end
  end
end

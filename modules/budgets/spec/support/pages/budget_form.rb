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

require "support/pages/page"

module Pages
  ##
  # Offers common steps for Budget Page instances.
  module BudgetForm
    ##
    # Adds planned unit costs with the default cost type.
    def add_unit_costs!(num_units, comment: nil, expected_costs: nil)
      edit_unit_costs! unit_rows, units: num_units, comment:, expected_costs:, type: "new"
      add_unit_costs_row!
    end

    ##
    # Adds planned labor costs with the default cost type.
    def add_labor_costs!(num_hours, user_name:, comment: nil, expected_costs: nil)
      edit_labor_costs!(labor_rows,
                        hours: num_hours,
                        user_name:,
                        comment:,
                        expected_costs:,
                        type: "new")
      add_labor_costs_row!
    end

    ##
    # Adds planned unit costs with the default cost type.
    #
    # @param type [String] Either 'existing' (default) or 'new'
    def edit_unit_costs!(id, units: nil, comment: nil, expected_costs: nil, type: :existing)
      prefix = "#{unit_cost_attr_id(type)}_#{id}"
      options = { fill_options: { clear: :backspace } }

      fill_in("#{prefix}_units", with: units, **options) if units.present?
      fill_in("#{prefix}_comments", with: comment, **options) if comment.present?
      expect(page).to have_css("##{prefix}_costs", text: expected_costs) if expected_costs.present?
    end

    def open_edit_planned_costs!(id, type:)
      row_id = "#budget_existing_#{type}_budget_item_attributes_#{id}"

      page.within row_id do
        find(".costs--edit-planned-costs-btn").click
      end
    end

    def edit_planned_costs!(id, costs:, type:)
      open_edit_planned_costs!(id, type:)

      row_id = "#budget_existing_#{type}_budget_item_attributes_#{id}"
      editor_name = "budget_existing_#{type}_budget_item_attributes_#{id}_amount"

      page.within row_id do
        fill_in editor_name, with: costs
      end

      submit_form!
    end

    # Submit the costs form
    def submit_form!
      find_by_id("budget-table--submit-button").click
    end

    ##
    # Adds planned labor costs with the default cost type.
    #
    # @param type [String] Either 'existing' (default) or 'new'
    def edit_labor_costs!(id, hours: nil, user_name: nil, comment: nil, expected_costs: nil, type: "existing")
      prefix = "#{labor_cost_attr_id(type)}_#{id}"
      options = { fill_options: { clear: :backspace } }

      fill_in("#{prefix}_hours", with: hours, **options) if hours.present?
      select user_name, from: "#{prefix}_user_id" if user_name.present?
      fill_in("#{prefix}_comments", with: comment, **options) if comment.present?

      expect(page).to have_css("##{prefix}_costs", text: expected_costs) if expected_costs.present?
    end

    def add_unit_costs_row!
      find("#material_budget_items_fieldset .wp-inline-create--add-link").click

      @unit_rows = unit_rows + 1
    end

    def add_labor_costs_row!
      find("#labor_budget_items_fieldset .wp-inline-create--add-link").click

      @labor_rows = labor_rows + 1
    end

    def expect_planned_costs!(type:, row:, expected:)
      raise "Unknown type: #{type}, allowed: labor, material" unless %i[labor material].include? type.to_sym

      retry_block(args: { tries: 3, base_interval: 5 }) do
        container = page.all("##{type}_budget_items_fieldset td.currency.budget-table--fields")[row - 1]
        actual = container.text
        raise "Expected planned costs #{expected}, got #{actual}" unless expected == actual
      end
    end

    def expect_subject(subject)
      expect(page)
        .to have_field("Subject", with: subject)
    end

    def unit_costs_at(num_row)
      unit_costs_container.all("tbody td.currency")[num_row - 1]
    end

    def overall_unit_costs
      unit_costs_container.first("tfoot td.currency")
    end

    def labor_costs_at(num_row)
      labor_costs_container.all("tbody td.currency")[num_row - 1]
    end

    def overall_labor_costs
      labor_costs_container.first("tfoot td.currency")
    end

    def unit_costs_container
      find_container(Budget.human_attribute_name(:material_budget))
    end

    def labor_costs_container
      find_container(Budget.human_attribute_name(:labor_budget))
    end

    def find_container(title)
      find("h4", text: title).find(:xpath, "..")
    end

    ##
    # @param type [String] Either 'new' or 'existing'
    def unit_cost_attr_id(type)
      "budget_#{type}_material_budget_item_attributes"
    end

    ##
    # @param type [String] Either 'new' or 'existing'
    def labor_cost_attr_id(type)
      "budget_#{type}_labor_budget_item_attributes"
    end

    def unit_rows
      @unit_rows ||= 0
    end

    def labor_rows
      @labor_rows ||= 0
    end

    def toast_type
      :rails
    end
  end
end

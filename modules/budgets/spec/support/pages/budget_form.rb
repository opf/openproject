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
    include ::Components::Autocompleter::NgSelectAutocompleteHelpers

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

      retry_block do
        fill_in("#{prefix}_units", with: units, **options) if units.present?
        fill_in("#{prefix}_comments", with: comment, **options) if comment.present?

        expect(page).to have_css("##{prefix}_costs", text: expected_costs) if expected_costs.present?
      end
    end

    def open_edit_planned_costs!(id, type:)
      find("#budget_existing_#{type}_budget_item_attributes_#{id} #{test_selector('edit_inline_cost')}").click
    end

    ##
    # Overrides the planned costs of a row and saves. A row that already has an
    # override is rendered with the override input open.
    def edit_planned_costs!(id, costs:, type:)
      editor_id = "budget_existing_#{type}_budget_item_attributes_#{id}_cost_override"

      open_edit_planned_costs!(id, type:) unless page.has_field?(editor_id, wait: 0)

      fill_in editor_id, with: costs, fill_options: { clear: :backspace }

      submit_form!
    end

    ##
    # Removes the override of a row, without saving.
    def cancel_planned_costs!(id, type:)
      find("#budget_existing_#{type}_budget_item_attributes_#{id} #{test_selector('cancel_inline_cost_edit')}").click
    end

    ##
    # The user autocompleters fill their hidden inputs once they are initialised.
    # A labor row submitted before that carries no user and is dropped on save.
    def expect_user_autocompleters_loaded!
      rows = "#labor_budget_items tbody tr[id^=budget_existing_labor]"

      expect(page).to have_css("#{rows} opce-user-autocompleter .ng-value", count: page.all(rows).size)
    end

    # Submit the costs form
    def submit_form!
      expect_user_autocompleters_loaded!
      find_test_selector("budgets-save-button").click
    end

    ##
    # Adds planned labor costs with the default cost type.
    #
    # @param type [String] Either 'existing' (default) or 'new'
    def edit_labor_costs!(id, hours: nil, user_name: nil, comment: nil, expected_costs: nil, type: "existing")
      prefix = "#{labor_cost_attr_id(type)}_#{id}"
      options = { fill_options: { clear: :backspace } }

      retry_block do
        select_labor_costs_user!(prefix, user_name) if user_name.present?
        fill_in("#{prefix}_hours", with: hours, **options) if hours.present?
        fill_in("#{prefix}_comments", with: comment, **options) if comment.present?

        expect(page).to have_css("##{prefix}_costs", text: expected_costs) if expected_costs.present?
      end
    end

    def select_labor_costs_user!(row_id, user_name)
      select_autocomplete page.find("##{row_id} opce-user-autocompleter"),
                          query: user_name,
                          results_selector: "body"
    end

    def add_unit_costs_row!
      find(:region, Budget.human_attribute_name(:material_budget))
        .click_on accessible_name: I18n.t(:button_add_budget_item)

      @unit_rows = unit_rows + 1
    end

    def add_labor_costs_row!
      find(:region, Budget.human_attribute_name(:labor_budget))
        .click_on accessible_name: I18n.t(:button_add_budget_item)

      @labor_rows = labor_rows + 1
    end

    def expect_planned_costs!(type:, row:, expected:)
      raise "Unknown type: #{type}, allowed: labor, material" unless %i[labor material].include? type.to_sym

      within(:region, Budget.human_attribute_name(:"#{type}_budget")) do
        container = find("tbody tr:nth-of-type(#{row}) td.currency")

        if container.has_field?(wait: 0)
          # A saved override is shown in the open override input, only the currency remains as text.
          amount = expected[/[\d.,]+/]

          expect(container).to have_field(with: amount)
          expect(container).to have_text(expected.sub(amount, "").strip)
        else
          expect(container).to have_text(expected, normalize_ws: true)
        end
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
  end
end

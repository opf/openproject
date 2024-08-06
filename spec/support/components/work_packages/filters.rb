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

require_relative "../../shared/selenium_workarounds"
require_relative "../autocompleter/ng_select_autocomplete_helpers"

module Components
  module WorkPackages
    class Filters
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include SeleniumWorkarounds
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      def open
        SeleniumHubWaiter.wait
        expect_loaded
        retry_block do
          # Run in retry block because filters do nothing if not yet loaded
          filter_button.click
          find(filters_selector, visible: true)
        end
      end

      def open!
        open
        expect_open
      end

      def expect_filter_count(num)
        expect(filter_button).to have_css(".badge", text: num, wait: 10)
      end

      def expect_open
        expect(page).to have_selector(filters_selector, wait: 5, visible: :visible)
      end

      def expect_closed
        expect(page).to have_selector(filters_selector, visible: :hidden)
      end

      def expect_quick_filter(text)
        expect(page).to have_field("filter-by-text-input", with: text)
      end

      def quick_filter(text)
        input = page.find_by_id("filter-by-text-input")
        input.hover
        input.click
        SeleniumHubWaiter.wait
        input.set text
      end

      def open_available_filter_list
        input = page.find(".advanced-filters--add-filter-value input")
        input.hover
        input.click
      end

      def expect_available_filter(name, present: true)
        # Ng-select dropdown can optimize the available options. If the list is long enough,
        # some filter options will not be rendered, thus the specs fail falsely.
        # We narrow the filter list by searching for the filter, thus we can be sure the
        # the option we are looking for is rendered.
        input = page.find(".advanced-filters--add-filter-value input")
        input.set name

        # The selector here is rather unspecific. Sometimes, we need ng-select to render the options outside of the
        # current element tree. However this means that the selector loses all feature specificity, as it's rendered
        # somewhere in the html body. This test assumes that only one ng-select can be opened at one time.
        # If you find errors with your specs related to the filter options, it might be coming from here.
        expect(page).to have_conditional_selector(present, ".ng-dropdown-panel .ng-option-label", text: name)

        # Reset the filter search input
        input.set ""
      end

      def expect_alternative_available_filter(search_term, displayed_name)
        input = page.find(".advanced-filters--add-filter-value input")
        input.set(search_term)

        expect(page)
          .to have_css(".ng-dropdown-panel .ng-option-label", text: displayed_name)

        input.set("")
      end

      def expect_loaded
        SeleniumHubWaiter.wait
        expect(filter_button).to have_css(".badge", wait: 2, visible: :all)
      end

      def add_filter(name)
        select_autocomplete page.find(".advanced-filters--add-filter-value"),
                            query: name,
                            results_selector: ".ng-dropdown-panel-items"
      end

      def add_filter_by(name, operator, value, selector = nil)
        add_filter(name)

        set_filter(name, operator, value, selector)

        # Wait for the debounce of the filter input to apply filters
        # See frontend/src/app/features/work-packages/components/filters/query-filters/query-filters.component.ts:69
        sleep 0.5
      end

      def set_operator(name, operator, selector = nil)
        id = selector || name.downcase

        select operator, from: "operators-#{id}"
      end

      def set_filter(name, operator, value, selector = nil)
        id = selector || name.downcase

        set_operator(name, operator, selector)

        set_value(id, value, operator) unless value.nil?

        close_autocompleter(id)
      end

      def expect_missing_filter(name)
        target_dropdown = search_autocomplete(page.find(".advanced-filters--add-filter-value"),
                                              query: name,
                                              results_selector: ".ng-dropdown-panel-items")

        within target_dropdown do
          expect(page).to have_no_css(".ng-option", text: name)
        end
      end

      def expect_filter_by(name, operator, value, selector = nil)
        id = selector || name.downcase

        expect(page).to have_select("operators-#{id}", selected: operator)

        if value == :placeholder
          expect_value_placeholder(id)
        elsif value
          expect_value(id, Array(value))
        else
          expect(page).to have_no_css("#values-#{id}")
        end
      end

      def expect_filter_value_by(name, operator, value, selector = nil)
        add_filter(name)

        id = selector || name.downcase

        set_operator(name, operator, selector)

        expect_autocomplete_value id, value

        remove_filter id
      end

      def expect_missing_filter_value_by(name, operator, value, selector = nil)
        add_filter(name)

        id = selector || name.downcase

        set_operator(name, operator, selector)

        expect_missing_autocomplete_value id, value

        remove_filter id
      end

      def expect_autocomplete_value(id, value)
        autocomplete_dropdown_value(id:, value:)
      end

      def expect_missing_autocomplete_value(id, value)
        autocomplete_dropdown_value(id:, value:, present: false)
      end

      def expect_no_filter_by(name, selector = nil)
        id = selector || name.downcase

        expect(page).to have_no_select("operators-#{id}")
        expect(page).to have_no_select("values-#{id}")
      end

      def expect_filter_order(name, values, selector = nil)
        id = selector || name.downcase

        expect(page.all("#values-#{id} .ng-value-label").map(&:text)).to eq(values)
      end

      def remove_filter(field)
        find("#filter_#{field} .advanced-filters--remove-filter-icon").click
      end

      def open_autocompleter(id)
        with_filter_input(id, &:click)
      end

      def close_autocompleter(id)
        with_filter_input(id) do |input|
          input.send_keys :escape
        end
      end

      protected

      def with_filter_input(id)
        filter_element = page.find("#filter_#{id}", match: :first)
        return if filter_element.has_no_selector?(".advanced-filters--filter-value .ng-input input", wait: false)

        yield filter_element.find(".ng-input input")
      end

      def filter_button
        find(button_selector)
      end

      def button_selector
        "#work-packages-filter-toggle-button"
      end

      def filters_selector
        ".work-packages--filters-optional-container"
      end

      def set_value(id, value, operator)
        retry_block do
          # wait for filter to be present
          filter_element = page.find("#filter_#{id}")
          if filter_element.has_selector?("[data-test-selector='op-basic-range-date-picker']", wait: false)
            insert_date_range(filter_element, value)
          elsif operator == "between"
            insert_two_single_dates(id, value)
          elsif filter_element.has_selector?(".ng-select-container", wait: false)
            insert_autocomplete_item(filter_element, value)
          else
            insert_plain_value(id, value)
          end
        end
      end

      def insert_autocomplete_item(filter_element, value)
        Array(value).each do |val|
          select_autocomplete filter_element.find("ng-select"),
                              query: val,
                              results_selector: ".ng-dropdown-panel-items"
        end
      end

      def insert_plain_value(id, value)
        within_values(id) do
          page.all("input").each_with_index do |input, index|
            # Wait a bit to insert the values
            ensure_value_is_input_correctly input, value: value[index]
          end
        end
      end

      def insert_two_single_dates(id, value)
        fill_in("values-#{id}-begin", with: value[0]) if value[0]
        fill_in("values-#{id}-end", with: value[1]) if value[1]

        ensure_value_is_input_correctly page.find("#values-#{id}-begin"), value: value[0] if value[0]
        ensure_value_is_input_correctly page.find("#values-#{id}-end"), value: value[1] if value[1]
      end

      def insert_date_range(filter_element, value)
        date_input = filter_element.find("[data-test-selector='op-basic-range-date-picker']")
        ensure_value_is_input_correctly date_input, value: Array(value).join(" - ")
      end

      def autocomplete_dropdown_value(id:, value:, present: true)
        filter_element = page.find("#filter_#{id}")

        if filter_element.has_selector?(".ng-select-container", wait: false)
          Array(value).each do |val|
            dropdown = search_autocomplete filter_element.find("ng-select"),
                                           query: val,
                                           results_selector: ".ng-dropdown-panel-items"
            expect(dropdown).to have_conditional_selector(present, ".ng-option", text: val)
          end
        end
      end

      def expect_value_placeholder(id)
        filter_element = page.find("#filter_#{id}")
        if filter_element.has_selector?(".ng-select-container", wait: false)
          expect(filter_element).to have_css(".ng-placeholder", text: I18n.t("js.placeholders.selection"))
        else
          raise "Non ng-select may not have placeholders currently"
        end
      end

      def expect_value(id, value)
        within_values(id) do |is_select|
          if is_select
            value.each do |v|
              expect(page).to have_css("#values-#{id} .ng-value-label", text: v)
            end
          elsif page.has_selector?("#filter_#{id} [data-test-selector='op-basic-range-date-picker']", wait: false)
            expected_value =
              if value[1]
                "#{value[0]} - #{value[1]}"
              elsif value[0]
                value[0].to_s
              else
                "-"
              end
            input = page.find("#filter_#{id} [data-test-selector='op-basic-range-date-picker']")
            expect(input.value).to eql(expected_value)
          else
            page.all("input").each_with_index do |input, index|
              expect(input.value).to eql(value[index])
            end
          end
        end
      end

      def within_values(id)
        page.within("#filter_#{id} .advanced-filters--filter-value", wait: 10) do
          yield page.has_selector?(".ng-select-container", wait: false)
        end
      end
    end
  end
end

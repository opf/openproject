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

module Components
  module Common
    module Filters
      include ::Components::Autocompleter::NgSelectAutocompleteHelpers

      def expect_filters_container_toggled
        expect(page).to have_css(".op-filters-form")
      end

      def expect_filters_container_hidden
        expect(page).to have_css(".op-filters-form", visible: :hidden)
      end

      def expect_filter_set(filter_name, value: nil)
        if filter_name == "name_and_identifier"
          expect(page.find_by_id(filter_name).value).not_to be_empty
        elsif value
          within(".advanced-filters--filter[data-filter-name='#{filter_name}']") do
            expect(page).to have_css(".advanced-filters--filter-value", text: value, visible: :all)
          end
        else
          expect(page)
            .to have_css(".advanced-filters--filter[data-filter-name='#{filter_name}']")
        end
      end

      def expect_filter_count(count)
        expect(page).to have_css('[data-test-selector="filters-button-counter"]', text: count)
      end

      def set_filter(name, human_name, human_operator = nil, values = [], send_keys: false)
        if name == "name_and_identifier"
          set_simple_filter(name, values, send_keys:)
        else
          set_advanced_filter(name, human_name, human_operator, values, send_keys:)
        end
      end

      def set_simple_filter(_name, values, send_keys: false)
        return unless values.any?

        set_name_and_identifier_filter(values, send_keys:) # This is the only one simple filter at the moment.
      end

      def set_advanced_filter(name, human_name, human_operator = nil, values = [], send_keys: false)
        selected_filter = select_filter(name, human_name)
        apply_operator(name, human_operator)

        within(selected_filter) do
          return unless values.any?

          if boolean_filter?(name)
            set_toggle_filter(values)
          elsif autocomplete_filter?(selected_filter)
            select(human_operator, from: "operator_#{name}")
            set_autocomplete_filter(values)
          elsif name == "created_at"
            select(human_operator, from: "operator_#{name}")
            set_datetime_filter(name, human_operator, values, send_keys:)
          elsif date_filter?(selected_filter) && human_operator == "on"
            set_date_filter(values, send_keys)
          end
        end
      end

      def expect_autocomplete_options_for(custom_field, options, grouping: nil, results_selector: "body")
        selected_filter = select_filter(custom_field.column_name, custom_field.name)

        within(selected_filter) do
          find('[data-filter-autocomplete="true"]').click
        end

        Array(options).each do |option|
          expect_ng_option(selected_filter, option, grouping:, results_selector:)
        end
      end

      def expect_user_autocomplete_options_for(custom_field, expected_options)
        selected_filter = select_filter(custom_field.column_name, custom_field.name)

        within(selected_filter) do
          find('[data-filter-autocomplete="true"]').click
        end

        expect_visible_user_auto_completer_options(expected_options)
      end

      def apply_operator(name, human_operator)
        select(human_operator, from: "operator_#{name}") unless boolean_filter?(name)
      end

      def select_filter(name, human_name)
        select human_name, from: "add_filter_select"
        page.find(".advanced-filters--filter[data-filter-name='#{name}']")
      end

      def remove_filter(name)
        if name == "name_and_identifier"
          page.find_by_id("name_and_identifier").find(:xpath, "following-sibling::button").click
        else
          page.find(".advanced-filters--filter[data-filter-name='#{name}'] .advanced-filters--remove-filter").click
        end
      end

      def set_toggle_filter(values)
        should_active = values.first == "yes"
        label = should_active ? I18n.t("general_text_Yes") : I18n.t("general_text_No")
        hidden = page.find('input[type="hidden"]', visible: :all)
        is_active = hidden.value == "t"

        click_button(label, exact: true) unless should_active == is_active

        expected_value = should_active ? "t" : "f"
        expect(page).to have_field(hidden["name"], with: expected_value, type: :hidden)
      end

      def set_name_and_identifier_filter(values, send_keys: false)
        if send_keys
          find_field("name_and_identifier").send_keys values.first
        else
          fill_in "name_and_identifier", with: values.first
        end
      end

      def set_datetime_filter(filter_name, human_operator, values, send_keys: false)
        case human_operator
        when "on", "less than days ago", "more than days ago", "days ago"
          if send_keys
            find_field(filter_name).send_keys values.first
          else
            fill_in filter_name, with: values.first
          end
        when "between"
          if send_keys
            value = values.join(" - ")
            find_field(filter_name).send_keys value
          else
            find_field(filter_name).click
            datepicker = ::Components::RangeDatepicker.new
            datepicker.set_date values.first
            datepicker.set_date values.last
          end
        end
      end

      def set_autocomplete_filter(values, clear: true)
        element = find('[data-filter-autocomplete="true"]')

        ng_select_clear(element, raise_on_missing: false) if clear

        Array(values).each do |query|
          select_autocomplete element,
                              query:,
                              results_selector: "body"
        end
      end

      def set_list_filter(values)
        value_select = find('.single-select select[name="value"]')
        value_select.select values.first
      end

      def set_date_filter(values, send_keys)
        if send_keys
          find_field("value").send_keys values.first
        else
          fill_in "value", with: values.first
        end
      end

      def open_filters
        return if filters_expanded?

        retry_block do
          toggle_filters_section
          expect(page).to have_css(".op-filters-form.-expanded")
          page.find_field("Add filter", visible: true)
        end
      end

      def filters_toggle
        page.find('[data-test-selector="filter-component-toggle"]')
      end

      def toggle_filters_section
        filters_toggle.click
      end

      def filters_expanded?
        # wait for widgets to be loaded (filters button should be visible)
        filters_toggle

        page.has_css?(".op-filters-form.-expanded", wait: 0)
      end

      def autocomplete_filter?(filter)
        filter.has_css?('[data-filter-autocomplete="true"]', wait: 0)
      end

      def date_filter?(filter)
        filter[:"data-filter-type"] == "date"
      end

      def date_time_filter?(filter)
        filter[:"data-filter-type"] == "datetime_past"
      end

      def boolean_filter?(_filter)
        false
      end
    end
  end
end

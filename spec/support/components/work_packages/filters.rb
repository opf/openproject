#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_relative '../../shared/selenium_workarounds'
require_relative '../ng_select_autocomplete_helpers'

module Components
  module WorkPackages
    class Filters
      include Capybara::DSL
      include RSpec::Matchers
      include SeleniumWorkarounds
      include ::Components::NgSelectAutocompleteHelpers

      def open
        retry_block do
          # Run in retry block because filters do nothing if not yet loaded
          filter_button.click
          find(filters_selector, visible: true)
        end
      end

      def expect_filter_count(num)
        expect(filter_button).to have_selector('.badge', text: num, wait: 10)
      end

      def expect_open
        expect(page).to have_selector(filters_selector, wait: 5, visible: true)
      end

      def expect_closed
        expect(page).to have_selector(filters_selector, visible: :hidden)
      end

      def expect_quick_filter(text)
        expect(page).to have_field('filter-by-text-input', with: text)
      end

      def quick_filter(text)
        input = page.find('#filter-by-text-input')
        input.hover
        input.click
        input.set text

        sleep 1
      end

      def expect_available_filter(name, present: true)
        expect(page).to have_conditional_selector(present, '.advanced-filters--add-filter-value option', text: name)
      end

      def expect_loaded
        expect(filter_button).to have_selector('.badge', wait: 20)
      end

      def add_filter_by(name, operator, value, selector = nil)
        select_autocomplete page.find('.advanced-filters--add-filter-value'),
                            query: name,
                            results_selector: '.ng-dropdown-panel-items'

        set_filter(name, operator, value, selector)
      end

      def set_operator(name, operator, selector = nil)
        id = selector || name.downcase

        select operator, from: "operators-#{id}"
      end

      def set_filter(name, operator, value, selector = nil)
        id = selector || name.downcase

        set_operator(name, operator, selector)

        set_value(id, value) unless value.nil?
      end

      def expect_filter_by(name, operator, value, selector = nil)
        id = selector || name.downcase

        expect(page).to have_select("operators-#{id}", selected: operator)

        if value == :placeholder
          expect_value_placeholder(id)
        elsif value
          expect_value(id, Array(value))
        else
          expect(page).to have_no_selector("#values-#{id}")
        end
      end

      def expect_no_filter_by(name, selector = nil)
        id = selector || name.downcase

        retry_block do
          page.raise_if_found_select("operators-#{id}")
          page.raise_if_found_select("values-#{id}")
        end
      end

      def expect_filter_order(name, values, selector = nil)
        id = selector || name.downcase

        expect(page.all("#values-#{id} .ng-value-label").map(&:text)).to eq(values)
      end

      def remove_filter(field)
        find("#filter_#{field} .advanced-filters--remove-filter-icon").click
      end

      protected

      def filter_button
        find(button_selector)
      end

      def button_selector
        '#work-packages-filter-toggle-button'
      end

      def filters_selector
        '.work-packages--filters-optional-container'
      end

      def set_value(id, value)
        retry_block do
          if page.has_selector?("#filter_#{id} .ng-select-container")
            Array(value).each do |val|
              select_autocomplete page.find("#filter_#{id}"),
                                  query: val,
                                  results_selector: '.advanced-filters--ng-select .ng-dropdown-panel-items'
            end
          else
            within_values(id) do
              page.all('input').each_with_index do |input, index|
                # Wait a bit to insert the values
                ensure_value_is_input_correctly input, value: value[index]
              end
            end
          end
        end
      end

      def expect_value_placeholder(id)
        if page.has_selector?("#filter_#{id} .ng-select-container")
          expect(page).to have_selector("#filter_#{id} .ng-placeholder", text: I18n.t('js.placeholders.selection'))
        else
          raise "Non ng-select may not have placeholders currently"
        end
      end

      def expect_value(id, value)
        within_values(id) do |is_select|
          if is_select
            value.each do |v|
              expect(page).to have_selector("#values-#{id} .ng-value-label", text: v)
            end
          else
            page.all('input').each_with_index do |input, index|
              expect(input.value).to eql(value[index])
            end
          end
        end
      end

      def within_values(id)
        page.within("#filter_#{id} .advanced-filters--filter-value", wait: 10) do
          yield page.has_selector?('.ng-select-container')
        end
      end
    end
  end
end

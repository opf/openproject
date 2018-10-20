#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module Components
  module WorkPackages
    class Filters
      include Capybara::DSL
      include RSpec::Matchers
      include SeleniumWorkarounds

      def open
        retry_block do
          # Run in retry block because filters do nothing if not yet loaded
          filter_button.click
          find(filters_selector, visible: true)
        end
      end

      def expect_filter_count(num)
        expect(filter_button).to have_selector('.badge', text: num)
      end

      def expect_open
        expect(page).to have_selector(filters_selector, wait: 5, visible: true)
      end

      def expect_closed
        expect(page).to have_selector(filters_selector, visible: :hidden)
      end

      def add_filter_by(name, operator, value, selector = nil)
        select name, from: "add_filter_select"

        set_filter(name, operator, value, selector)
      end

      def set_operator(name, operator, selector = nil)
        id = selector || name.downcase

        select operator, from: "operators-#{id}"
      end

      def set_filter(name, operator, value, selector = nil)
        id = selector || name.downcase

        set_operator(name, operator, selector)

        set_value(id, value)
      end

      def expect_filter_by(name, operator, value, selector = nil)
        id = selector || name.downcase

        expect(page).to have_select("operators-#{id}", selected: operator)

        if value
          expect_value(id, value)
        else
          expect(page).to have_no_select("values-#{id}")
        end
      end

      def expect_no_filter_by(name, selector = nil)
        id = selector || name.downcase

        expect(page).to have_no_select("operators-#{id}")
        expect(page).to have_no_select("values-#{id}")
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
        within_values(id) do |is_select|
          if is_select
            select value, from: "values-#{id}"
          else
            page.all('input').each_with_index do |input, index|
              # Wait a bit to insert the values
              ensure_value_is_input_correctly input, value: value[index]
            end
          end
        end
      end

      def expect_value(id, value)
        within_values(id) do |is_select|
          if is_select
            expect(page).to have_select("values-#{id}", selected: value)
          else
            page.all('input').each_with_index do |input, index|
              expect(input.value).to eql(value[index])
            end
          end
        end
      end

      def within_values(id)
        page.within("#filter_#{id} .advanced-filters--filter-value", wait: 10) do
          inputs = page.first('select, input')

          yield inputs.tag_name == 'select'
        end
      end
    end
  end
end

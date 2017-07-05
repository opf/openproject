#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Components
  module WorkPackages
    class Filters
      include Capybara::DSL
      include RSpec::Matchers

      def open
        filter_button.click
        expect_open
      end

      def expect_filter_count(num)
        expect(filter_button).to have_selector('.badge', text: num)
      end

      def expect_open
        expect(page).to have_selector(filters_selector, visible: true)
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
        page.within(filters_selector) do
          find("#filter_#{field} .advanced-filters--remove-filter-icon").click
        end
      end

      private

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
              input.set value[index]
              sleep(0.5)
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
        page.within("#div-values-#{id}", wait: 10) do
          inputs = page.first('select, input')

          yield inputs.tag_name == 'select'
        end
      end
    end
  end
end

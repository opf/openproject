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

      def filter_by_watcher(name)
        select "Watcher", from: "add_filter_select"
        select name, from: "values-watcher"
      end

      # limited to select fields for now
      def add_filter_by(name, operator, value, selector = nil)
        id = selector || name.downcase

        select name, from: "add_filter_select"
        select operator, from: "operators-#{id}"
        select value, from: "values-#{id}"
      end

      # limited to select fields for now
      def expect_filter_by(name, operator, value, selector = nil)
        id = selector || name.downcase

        expect(page).to have_select("operators-#{id}", selected: operator)
        expect(page).to have_select("values-#{id}", selected: value)
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
    end
  end
end

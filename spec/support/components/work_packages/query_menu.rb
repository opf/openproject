#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

require 'features/support/components/ui_autocomplete'

module Components
  module WorkPackages
    class QueryMenu
      include Capybara::DSL
      include RSpec::Matchers
      include ::Components::UIAutocompleteHelpers

      def select(query)
        select_autocomplete autocompleter,
                            results_selector: autocompleter_results_selector,
                            item_selector: autocompleter_item_selector,
                            query: query
      end

      def autocompleter
        page.find autocompleter_selector
      end

      def autocompleter_results_selector
        '.op-view-select--search-results'
      end

      def autocompleter_item_selector
        '.op-sidemenu--item-title'
      end

      def autocompleter_selector
        '#query-title-filter'
      end

      def expect_menu_entry(name)
        expect(page).to have_selector(autocompleter_item_selector, text: name)
      end

      def expect_menu_entry_not_visible(name)
        expect(page).not_to have_selector(autocompleter_item_selector, text: name)
      end

      def expect_no_menu_entry
        expect(page).not_to have_selector(autocompleter_item_selector)
      end
    end
  end
end

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
require 'support/components/autocompleter/autocomplete_helpers'

module Components
  module Projects
    class TopMenu
      include Capybara::DSL
      include RSpec::Matchers
      include ::Components::Autocompleter::AutocompleteHelpers

      def toggle
        page.find('#projects-menu').click
      end

      def expect_current_project(name)
        expect(page).to have_selector('#projects-menu', text: name)
      end

      def expect_open
        expect(page).to have_selector(autocompleter_selector)
      end

      def expect_closed
        expect(page).to have_no_selector(autocompleter_selector)
      end

      def search(query)
        search_autocomplete(autocompleter, query:, results_selector: autocompleter_results_selector)
      end

      def clear_search
        autocompleter.set ''
        autocompleter.send_keys :backspace
      end

      def search_and_select(query)
        select_autocomplete autocompleter,
                            results_selector: autocompleter_results_selector,
                            item_selector: autocompleter_item_title_selector,
                            query:
      end

      def search_results
        page.find autocompleter_results_selector
      end

      def autocompleter
        page.find autocompleter_selector
      end

      def expect_result(name, disabled: false)
        within search_results do
          if disabled
            expect(page).to have_selector(autocompleter_item_disabled_title_selector, text: name)
          else
            expect(page).to have_selector(autocompleter_item_title_selector, text: name)
          end
        end
      end

      def expect_no_result(name)
        within search_results do
          expect(page).to have_no_selector(autocompleter_item_title_selector, text: name)
        end
      end

      def expect_item_with_hierarchy_level(hierarchy_level:, item_name:)
        within search_results do
          hierarchy_selector  = hierarchy_level.times.collect { autocompleter_item_selector }.join(' ')
          expect(page)
            .to have_selector("#{hierarchy_selector} #{autocompleter_item_title_selector}", text: item_name)
        end
      end

      def autocompleter_item_selector
        '[data-qa-selector="op-project-list--item"]'
      end

      def autocompleter_item_title_selector
        '[data-qa-selector="op-project-list--item-title"]'
      end

      def autocompleter_item_disabled_title_selector
        '[data-qa-selector="op-project-list--item-disabled-title"]'
      end

      def autocompleter_results_selector
        '[data-qa-selector="op-project-menu-autocomplete--list"]'
      end

      def autocompleter_selector
        '[data-qa-selector="op-project-menu-autocomplete--search"] input'
      end
    end
  end
end

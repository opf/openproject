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
  class Submenu
    include Capybara::DSL
    include Capybara::RSpecMatchers
    include RSpec::Matchers

    def expect_open
      expect(page).to have_css('[data-test-selector="op-submenu"]')
    end

    def expect_item(name, selected: false, favored: nil, visible: true)
      within "#main-menu" do
        selected_specifier = selected ? ".selected" : ":not(.selected)"

        if favored.nil?
          expect(page).to have_css(".op-submenu--item-action#{selected_specifier}", text: name, visible:)
        else
          item = page.find(".op-submenu--item-action#{selected_specifier}", text: name, visible:)

          if favored
            expect(item).to have_css(".op-primer--star-icon")
          else
            expect(item).to have_no_css(".op-primer--star-icon")
          end
        end
      end
    end

    def expect_no_item(name)
      within "#main-menu" do
        expect(page).not_to have_test_selector("op-submenu--item-action", text: name)
      end
    end

    def expect_item_with_count(item, count)
      within page.find_test_selector("op-submenu--item-action", text: item) do
        expect_count count
      end
    end

    def expect_item_with_no_count(item)
      within page.find_test_selector("op-submenu--item-action", text: item) do
        expect_no_count
      end
    end

    def click_item(name)
      within "#main-menu" do
        click_on text: name
      end
    end

    def expect_no_items
      within "#main-menu" do
        expect(page).not_to have_test_selector("op-submenu--item-action")
      end
    end

    def search_for_item(name)
      within "#main-menu" do
        page.find_test_selector("op-submenu--search-input").set(name)
      end
    end

    def finished_loading
      wait_for_network_idle
    end

    def expect_no_results_text
      within "#main-menu" do
        expect(page).to have_test_selector("op-submenu--search-no-results", text: "No items found")
      end
    end

    def expect_count(count)
      expect(page).to have_test_selector("op-submenu--item-count", text: count)
    end

    def expect_no_count
      expect(page).not_to have_test_selector("op-submenu--item-count")
    end
  end
end

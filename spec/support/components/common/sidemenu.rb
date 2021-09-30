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

module Components
  module Notifications
    class Sidemenu
      include Capybara::DSL
      include RSpec::Matchers

      def initialize; end

      def expect_open
        expect(page).to have_selector('[data-qa-selector="op-sidemenu"]')
      end

      def expect_item_not_visible(item)
        expect(page).to have_no_selector(item_selector, text: item)
      end

      def expect_item_with_count(item, count)
        within item_action_selector(item) do
          expect(page).to have_text item
          expect_count(count)
        end
      end

      def expect_item_with_no_count(item)
        within item_action_selector(item) do
          expect(page).to have_text item
          expect_no_count
        end
      end

      def click_item(item)
        page.find(item_action_selector(item), text: item).click
      end

      def finished_loading
        expect(page).to have_no_selector('.op-ian-center--loading-indicator')
      end

      private

      def expect_count(count)
        expect(page).to have_selector('.op-bubble', text: count)
      end

      def expect_no_count
        expect(page).to have_no_selector('.op-bubble')
      end

      def item_action_selector(item)
        "[data-qa-selector='op-sidemenu--item-action--#{item.delete(' ')}']"
      end

      def item_selector
        '[data-qa-selector="op-sidemenu--item"]'
      end
    end
  end
end

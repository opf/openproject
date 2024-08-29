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

require_relative "../../toasts/expectations"

module Components
  module WorkPackages
    class SettingsMenu
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include Toasts::Expectations

      def open_and_save_query(name)
        open_and_choose("Save")
        within_modal_fill_in_and_save(name:)
      end

      def open_and_save_query_as(name)
        open_and_choose("Save as")
        within_modal_fill_in_and_save(name:)
      end

      def open_and_choose(name)
        retry_block do
          open!
          choose(name)
        end
      end

      def open!
        click_on "work-packages-settings-button"
        dropdown_menu
      end

      def dropdown_menu
        page.find(selector)
      end

      def expect_open
        expect(page).to have_selector(selector)
      end

      def expect_closed
        expect(page).to have_no_selector(selector)
      end

      def choose(target)
        find("#{selector} .menu-item", text: target, match: :prefer_exact).click
      end

      def expect_options(*options)
        expect_open
        options.each do |text|
          expect(page).to have_css("#{selector} a", text:)
        end
      end

      private

      def selector
        "#settingsDropdown"
      end

      def within_modal_fill_in_and_save(name:)
        modal.within_modal do
          fill_in "save-query-name", with: name
          click_button "Save"
        end
        wait_for_save_completion
      end

      def wait_for_save_completion
        expect_and_dismiss_toaster
        modal.expect_closed
      end

      def modal
        Components::Common::Modal.new
      end
    end
  end
end

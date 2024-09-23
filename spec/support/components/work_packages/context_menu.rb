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
    class ContextMenu
      include Capybara::DSL
      include Capybara::RSpecMatchers
      include RSpec::Matchers
      include Toasts::Expectations

      def open_for(work_package, card_view: nil)
        # Close
        find("body").send_keys :escape
        sleep 0.5 unless using_cuprite?

        retry_block do
          if card_view
            page.find(".op-wp-single-card-#{work_package.id}").right_click
          else
            page.find(".wp-row-#{work_package.id}-table").right_click
          end

          raise "Menu not open" unless page.find(:menu, work_package_context_menu_label)
        end
      rescue StandardError
        expect_open
      end

      def expect_open
        expect(page).to have_selector(:menu, work_package_context_menu_label)
      end

      def expect_closed
        expect(page).to have_no_selector(:menu, work_package_context_menu_label)
      end

      def choose(target)
        within_menu do
          find(:menuitem, text: target, exact_text: true).click
        end
      end

      def choose_delete_and_confirm_deletion
        choose "Delete"
        # only handle the case where the modal does _not_ ask for descendants deletion confirmation
        within_modal(I18n.t("js.modals.destroy_work_package.title", label: "work package")) do
          click_button "Delete"
        end
        expect_and_dismiss_toaster
      end

      def expect_no_options(*options)
        expect_open
        within_menu do
          options.each do |text|
            expect(page).to have_no_selector(:menuitem, text:)
          end
        end
      end

      def expect_options(*options)
        expect_open
        within_menu do
          options.each do |text|
            expect(page).to have_selector(:menuitem, text:)
          end
        end
      end

      private

      def within_menu(&)
        within(:menu, work_package_context_menu_label, &)
      end

      def work_package_context_menu_label
        I18n.t("js.label_work_package_context_menu")
      end
    end
  end
end

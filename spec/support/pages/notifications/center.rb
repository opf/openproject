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

module Pages
  module Notifications
    class Center < ::Pages::Page
      def open
        bell_element.click
        wait_for_network_idle
        expect_open
      end

      def path
        notifications_center_path
      end

      def mark_all_read
        click_link_or_button "Mark all as read"
      end

      def mark_notification_as_read(notification)
        within_item(notification) do
          page.find('[data-test-selector="mark-as-read-button"]').click
        end
      end

      def show_all
        click_button "All"
      end

      def item_title(notification)
        text = notification.resource.is_a?(WorkPackage) ? notification.resource.subject : notification.subject
        within_item(notification) do
          page.find("span", text:, exact_text: true)
        end
      end

      def click_item(notification)
        item_title(notification).click
      end

      def double_click_item(notification)
        item_title(notification).double_click
      end

      def within_item(notification, &)
        page.within("[data-test-selector='op-ian-notification-item-#{notification.id}']", &)
      end

      def expect_item(notification, expected_text = notification.subject)
        within_item(notification) do
          expect(page).to have_text expected_text, normalize_ws: true
        end
      end

      def expect_no_item(*notifications)
        notifications.each do |notification|
          expect(page)
            .to have_no_css("[data-test-selector='op-ian-notification-item-#{notification.id}']")
        end
      end

      def expect_read_item(notification)
        expect(page)
          .to have_css("[data-test-selector='op-ian-notification-item-#{notification.id}'][data-qa-ian-read]")
      end

      def expect_item_not_read(notification)
        expect(page)
          .to have_no_css("[data-test-selector='op-ian-notification-item-#{notification.id}'][data-qa-ian-read]")
      end

      def expect_item_selected(notification)
        expect(page)
          .to have_css("[data-test-selector='op-ian-notification-item-#{notification.id}'][data-qa-ian-selected]")
      end

      def expect_work_package_item(*notifications)
        notifications.each do |notification|
          work_package = notification.resource
          raise(ArgumentError, "Expected work package") unless work_package.is_a?(WorkPackage)

          expect_item notification,
                      "#{work_package.type.name.upcase} #{work_package.subject}"
        end
      end

      def expect_closed
        expect(page).to have_no_css("opce-notification-center")
      end

      def expect_open
        expect(page).to have_css("opce-notification-center")
      end

      def expect_empty
        expect(page).to have_text "New notifications will appear here when there is activity that concerns you"
      end

      def expect_number_of_notifications(count)
        if count == 0
          expect(page).to have_no_css('[data-test-selector^="op-ian-notification-item-"]')
        else
          expect(page).to have_css('[data-test-selector^="op-ian-notification-item-"]', count:, wait: 10)
        end
      end

      def expect_bell_count(count)
        if count == 0
          expect(page).to have_no_css('[data-test-selector="op-ian-notifications-count"]')
        else
          expect(page).to have_css('[data-test-selector="op-ian-notifications-count"]', text: count, wait: 10)
        end
      end

      def bell_element
        page.find('opce-in-app-notification-bell [data-test-selector="op-ian-bell"]')
      end

      def expect_no_toaster
        expect(page).to have_no_css(".op-toast.-info", wait: 10)
      end

      def expect_toast
        expect(page).to have_css(".op-toast.-info", wait: 10)
      end

      def update_via_toaster
        page.find(".op-toast.-info a", wait: 10).click
      end
    end
  end
end

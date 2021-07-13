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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Components
  module Notifications
    class Center
      include Capybara::DSL
      include RSpec::Matchers

      def initialize; end

      def open
        bell_element.click
        expect_open
      end

      def close
        page.find('button[data-qa-selector="op-modal-close"]').click
        expect_closed
      end

      def mark_all_read
        click_button 'Mark all as read'
      end

      def click_item(notification)
        text = notification.resource.is_a?(WorkPackage) ? notification.resource.subject : notification.subject
        within_item(notification) do
          page.find('span', text: text, exact_text: true).click
        end
      end

      def within_item(notification, &block)
        page.within("[data-qa-selector='op-ian-notification-item-#{notification.id}']", &block)
      end

      def expect_item(notification, subject: notification.subject)
        within_item(notification) do
          expect(page).to have_text subject
        end
      end

      def expect_read_item(notification)
        expect(page)
          .to have_selector("[data-qa-selector='op-ian-notification-item-#{notification.id}'][data-qa-ian-read]")
      end

      def expect_expanded(notification)
        within_item(notification) do
          expect(page).to have_selector('[data-qa-selector="op-ian-details"]')
        end
      end

      def expect_work_package_item(notification)
        work_package = notification.resource
        raise(ArgumentError, "Expected work package") unless work_package.is_a?(WorkPackage)

        expect_item notification,
                    subject: "#{work_package.type.name.upcase} ##{work_package.id} #{work_package.subject}"
      end

      def expect_closed
        expect(page).to have_no_selector('op-in-app-notification-center')
      end

      def expect_open
        expect(page).to have_selector('op-in-app-notification-center')
      end

      def expect_empty
        expect(page).to have_text I18n.t('js.notice_no_results_to_display')
      end

      def expect_bell_count(count)
        if count == 0
          expect(page).to have_no_selector('[data-qa-selector="op-ian-notifications-count"]')
        else
          expect(page).to have_selector('[data-qa-selector="op-ian-notifications-count"]', text: count, wait: 20)
        end
      end

      def bell_element
        page.find('op-in-app-notification-bell button')
      end
    end
  end
end
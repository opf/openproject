# frozen_string_literal: true

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

require "support/pages/page"

module Pages
  module Admin
    class Statuses < ::Pages::Page
      def path = "/statuses"

      def expect_listed(*names)
        page.document.synchronize do
          found = page.all("#{row_selector} a").map(&:text)

          raise Capybara::ExpectationNotMet, "Expected #{names}, got #{found}" unless found == names
        end
      end

      def within_status(status, &)
        within_test_selector("status-row-#{status.id}", &)
      end

      def click_status_action(status, action:)
        within_status(status) do
          click_on accessible_name: I18n.t("statuses.index.status_actions")
          click_on action
        end
      end

      def drag_status(from_index:, to_index:)
        drag_and_drop_list(from: from_index, to: to_index, elements: row_selector, handler: ".DragHandle")
      end

      def go_to_page(number)
        within(".op-pagination--pages") { click_on number.to_s }
      end

      def set_page_size(size)
        within(".op-pagination--options") { click_on size.to_s }
      end

      private

      def row_selector = "[data-test-selector^='status-row-']"
    end
  end
end

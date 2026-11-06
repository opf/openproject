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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "support/pages/page"

module Pages
  module Admin
    module PlaceholderUsers
      class Index < ::Pages::Page
        def path
          "/placeholder_users"
        end

        def expect_listed(*placeholder_users)
          placeholder_users.each do |user|
            expect(page).to have_css(name_cell_selector, text: user.name, exact_text: true)
          end
        end

        def expect_not_listed(*users)
          users.each do |user|
            expect(page).to have_no_css(name_cell_selector, text: user.name, exact_text: true)
          end
        end

        def expect_non_listed
          expect(page).to have_no_css(row_selector)
          expect(page).to have_css(".blankslate")
        end

        def filter_by_name(value)
          within("#content") do
            click_button accessible_name: "Search"
          end
          fill_in "Search", with: value

          wait_for_network_idle
        end

        def clear_filters
          visit!
        end

        def expect_no_delete_button_for_all_rows
          expect(page).to have_css("i.icon-help2")
        end

        def expect_no_delete_button(placeholder_user)
          within_placeholder_user_row(placeholder_user) do
            expect(page).to have_css("i.icon-help2")
          end
        end

        def expect_delete_button(placeholder_user)
          within_placeholder_user_row(placeholder_user) do
            expect(page).to have_link(accessible_name: I18n.t("placeholder_users.delete_tooltip"))
          end
        end

        def click_placeholder_user_button(placeholder_user, text)
          within_placeholder_user_row(placeholder_user) do
            click_link text
          end
        end

        private

        def row_selector
          "[role='row'].placeholder_user"
        end

        def name_cell_selector
          "#{row_selector} .op-border-box-grid__row-item:first-child"
        end

        def within_placeholder_user_row(placeholder_user, &)
          row = page.find(row_selector) do |row|
            row.has_css?(".op-border-box-grid__row-item:first-child", text: placeholder_user.name, exact_text: true)
          end
          within(row, &)
        end
      end
    end
  end
end

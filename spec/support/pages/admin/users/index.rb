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
    module Users
      class Index < ::Pages::Page
        include ::Components::Common::Filters

        def path
          "/users"
        end

        def expect_listed(*users)
          # Wait for each expected user to appear (have_css auto-waits, page.all does not),
          # then assert the total row count to catch unexpected extras.
          users.each do |user|
            expect(page).to have_css("td.username a", text: user.login)
          end
          expect(page).to have_css("td.username a", count: users.count)
        end

        def expect_order(*users)
          rows = page.all "td.username a", count: users.count
          expect(rows.map(&:text)).to eq(users.map(&:login))
        end

        def expect_non_listed
          expect(page)
            .to have_no_css("tr.user")

          expect(page)
            .to have_css("tr.generic-table--empty-row", text: "There is currently nothing to display.")
        end

        def expect_not_listed(*users)
          users.each do |user|
            expect(page).to have_no_css("td.username a", text: user.login)
          end
        end

        def expect_user_locked(user)
          expect(page)
            .to have_css("tr.user.locked td.username", text: user.login)
        end

        def filter_by_status(value)
          open_filter_panel
          unless page.has_css?(".advanced-filters--filter[data-filter-name='status']")
            select "Status", from: "add_filter_select"
          end
          within(".advanced-filters--filter[data-filter-name='status']") do
            set_autocomplete_filter([value])
          end

          wait_for_network_idle
        end

        def filter_by_name(value)
          within("#content") do
            click_button accessible_name: "Search"
          end
          fill_in "Search", with: value

          wait_for_network_idle
        end

        def filter_by_group(value)
          open_filter_panel
          unless page.has_css?(".advanced-filters--filter[data-filter-name='group']:not([hidden])")
            select "Group", from: "add_filter_select"
          end

          within_filter("group") do
            select_autocomplete find('[data-filter-autocomplete="true"]'),
                                query: value,
                                results_selector: "body"
          end

          wait_for_network_idle
        end

        def expect_group_filter(value)
          open_filter_panel

          within_filter("group") do
            expect_current_autocompleter_value find('[data-filter-autocomplete="true"]'), value
          end
        end

        def clear_filters
          find_by_id("user-filters-form-clear-button").click

          wait_for_network_idle
        end

        def open_filter_panel
          return if filter_panel_open?

          find("[data-test-selector='filter-component-toggle']").click
          # Wait for the toggle's Stimulus action to actually expand the panel —
          # otherwise subsequent selectors run against still-collapsed (hidden) UI.
          expect(page).to have_css(".op-filters-form.-expanded")
        end

        def filter_panel_open?
          page.has_css?(".op-filters-form.-expanded", wait: 0)
        end

        def within_filter(name, &)
          within(".advanced-filters--filter[data-filter-name='#{name}']:not([hidden])", &)
        end

        def order_by(key)
          within "thead" do
            click_link key
          end

          wait_for_network_idle
        end

        def lock_user(user)
          click_user_button(user, "Lock permanently")
        end

        def activate_user(user)
          click_user_button(user, "Activate")
        end

        def reset_failed_logins(user)
          click_user_button(user, "Reset failed logins")
        end

        def unlock_user(user)
          click_user_button(user, "Unlock")
        end

        def unlock_and_reset_user(user)
          click_user_button(user, "Unlock and reset failed logins")
        end

        def click_user_button(user, text)
          within_user_row(user) do
            click_link text
          end

          wait_for_network_idle
        end

        private

        def within_user_row(user, &)
          row = find("tr.user", text: user.login)
          within(row, &)
        end
      end
    end
  end
end

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
    module PlaceholderUsers
      class Index < ::Pages::Page
        def path
          "/placeholder_users"
        end

        def expect_listed(*placeholder_users)
          rows = page.all "td.name"
          expect(rows.map(&:text)).to include(*placeholder_users.map(&:name))
        end

        def expect_ordered(*placeholder_users)
          rows = page.all "td.name"
          expect(rows.map(&:text)).to eq(placeholder_users.map(&:name))
        end

        def expect_not_listed(*users)
          rows = page.all "td.name"
          expect(rows.map(&:text)).not_to include(*users.map(&:name))
        end

        def expect_non_listed
          expect(page)
            .to have_no_css("tr.placeholder-user")

          expect(page)
            .to have_css("tr.generic-table--empty-row", text: "There is currently nothing to display.")
        end

        def filter_by_name(value)
          fill_in "Name", with: value
          click_button "Apply"
        end

        def clear_filters
          click_link "Clear"
        end

        def order_by(key)
          within "thead" do
            click_link key
          end
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
            expect(page).to have_css("i.icon-delete")
          end
        end

        def click_placeholder_user_button(placeholder_user, text)
          within_placeholder_user_row(placeholder_user) do
            click_link text
          end
        end

        private

        def within_placeholder_user_row(placeholder_user, &)
          row = find("tr.placeholder_user td.name", text: placeholder_user.name).ancestor("tr")
          within(row, &)
        end
      end
    end
  end
end

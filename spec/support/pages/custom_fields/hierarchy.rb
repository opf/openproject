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
  module CustomFields
    class Hierarchy < Page
      def path
        case @tab
        when "items"
          "/admin/settings/work_package_custom_fields/#{@custom_field.id}/items"
        when "projects"
          "/admin/settings/work_package_custom_fields/#{@custom_field.id}/projects"
        else
          "/admin/settings/work_package_custom_fields/#{@custom_field.id}/edit"
        end
      end

      def add_custom_field_state(custom_field)
        @custom_field = custom_field
      end

      def switch_tab(tab)
        @tab = tab.downcase

        within_test_selector("custom_field_detail_header") do
          click_on "Items"
        end
      end

      def expect_tab(tab)
        @tab = tab.downcase

        within_test_selector("custom_field_detail_header") do
          expect(page).to have_css("a[href='#{path}']", text: tab, aria: { current: "page" })
        end
      end

      def open_action_menu_for(label)
        within_test_selector("op-custom-fields--hierarchy-item", text: label) do
          within_test_selector("op-hierarchy-item--action-menu") do
            click_on
          end
        end
      end
    end
  end
end

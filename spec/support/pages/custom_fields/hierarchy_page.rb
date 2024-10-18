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
  module CustomFields
    class HierarchyPage < Page
      def path
        case @tab
        when "items"
          "/custom_fields/#{@custom_field.id}/items"
        when "projects"
          "/custom_fields/#{@custom_field.id}/projects"
        else
          "/custom_fields/#{@custom_field.id}/edit"
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

      def expect_empty_items_banner(visible:)
        if visible
          expect(page).to have_test_selector("op-custom-fields--new-hierarchy-banner")
        else
          expect(page).not_to have_test_selector("op-custom-fields--new-hierarchy-banner")
        end
      end

      def expect_header_text(text)
        expect(page).to have_css(".PageHeader-title", text: text)
      end

      def expect_blank_slate(visible:)
        if visible
          expect(page).to have_test_selector("op-custom-fields--hierarchy-items-blankslate")
        else
          expect(page).not_to have_test_selector("op-custom-fields--hierarchy-items-blankslate")
        end
      end

      def expect_items_count(count)
        expect(page).to have_test_selector("op-custom-fields--hierarchy-item", count:)
      end

      def expect_hierarchy_item(label:, short: nil, visible: true)
        if visible
          expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: label)
          expect(page).to have_test_selector("op-custom-fields--hierarchy-item", text: short) unless short.nil?
        else
          expect(page).not_to have_test_selector("op-custom-fields--hierarchy-item", text: label)
        end
      end

      def expect_inline_form(visible:)
        if visible
          expect(page).to have_test_selector("op-custom-fields--new-item-form")
        else
          expect(page).not_to have_test_selector("op-custom-fields--new-item-form")
        end
      end

      def expect_deletion_dialog(visible:)
        if visible
          expect(page).to have_test_selector("op-custom-fields--delete-item-dialog")
        else
          expect(page).not_to have_test_selector("op-custom-fields--delete-item-dialog")
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

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
  module Types
    # Drives the type index; type groups are addressed by name.
    class Index < ::Pages::Page
      def path
        "/types"
      end

      def type_list
        page.find(:list, accessible_name: I18n.t(:label_type_plural))
      end

      def type_group(type)
        type_list.find(:heading, canonical_name(type), exact: true).ancestor(:list_item)
      end

      def within_type_header(type, &)
        within(type_group(type).find(".Box-header"), &)
      end

      def within_actions_menu(type, &)
        within_type_header(type) do
          within(open_controlled_menu(find(:button, accessible_name: I18n.t(:label_actions))), &)
        end
      end

      def move(type, direction_label)
        within_actions_menu(type) do |menu|
          within(open_controlled_menu(menu.find(:menuitem, I18n.t(:button_move), exact: true))) do |submenu|
            wait_for_turbo_stream { submenu.find(:menuitem, direction_label, exact: true).click }
          end
        end
      end

      def drag(type, before:)
        target = type_group(before)

        perform_native_drag(source: drag_handle(type), target:, offset_y: -(target.native.rect.height / 4))
      end

      def expect_page_order(*names)
        page.document.synchronize do
          found = type_list.all(:heading).map { it.text.squish }
          raise Capybara::ExpectationNotMet, "Expected #{names}, got #{found}" unless found == names
        end
      end

      def expect_db_order(*names)
        expect(::Type.order(:position).pluck(:name)).to eq(names)
      end

      def expect_listed(*types)
        headers = page.all(".Box-header .Button-label, .Box-header a")

        expect(headers.map(&:text)).to include(*types.map { |t| canonical_name(t) })
      end

      def click_new
        page.find_test_selector("op-admin-types--button-new", text: "Type").click
      end

      def delete(type)
        click_delete(type)

        expect(page).to have_css("##{deletion_dialog_id}[open]")

        within("##{deletion_dialog_id}") { click_button I18n.t(:button_delete) }
      end

      def delete_expecting_refusal(type)
        click_delete(type)
      end

      private

      def click_delete(type)
        within_actions_menu(type) { |menu| menu.find(:menuitem, I18n.t(:button_delete)).click }
      end

      def drag_handle(type)
        type_group(type).find(:button, accessible_name: I18n.t("drag_handle.button_drag"))
      end

      def open_controlled_menu(button)
        button.click
        page.find(:menu, id: button["aria-controls"])
      end

      def deletion_dialog_id
        WorkPackageTypes::Types::TypeDeletionDialogComponent::DIALOG_ID
      end

      def canonical_name(type)
        type.respond_to?(:name) ? type.name : type
      end
    end
  end
end

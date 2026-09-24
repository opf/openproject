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
    # Drives the enumeration admin lists (priorities, time entry activities,
    # document types). Subclasses define `path`, `list_selector` and
    # `actions_label`, and override `item_selector` for tables; records are
    # addressed by name.
    class EnumerationList < ::Pages::Page
      def item_selector = :list_item

      def within_list(&)
        within(list_selector, &)
      end

      def within_row(record, &)
        within_list { within(item_selector, record.name, &) }
      end

      def expect_order(*names)
        within_list do
          expect(page).to have_selector(item_selector, count: names.size)
          names.each_with_index do |name, index|
            expect(page).to have_selector(item_selector, name, position: index + 1)
          end
        end
      end

      def expect_move_settled(*names)
        expect_and_dismiss_flash(message: I18n.t(:enumeration_caption_order_changed))
        expect_order(*names)
        expect(page).to have_no_css("[data-sortable-lists-busy]")
      end

      def within_menu(record, &)
        within_row(record) do
          button = find(:button, accessible_name: actions_label)
          within(open_controlled_menu(button), &)
        end
      end

      def within_move_submenu(record, &)
        within_menu(record) do |menu|
          within(open_controlled_menu(menu.find(:menuitem, I18n.t(:button_move))), &)
        end
      end

      def move(record, direction_label)
        within_move_submenu(record) do |submenu|
          submenu.find(:menuitem, direction_label).click
        end
      end

      def drag(record, after:)
        handle = drag_handle(record)
        target = row(after)
        offset_y = (target.native.rect.height / 2) - [6, target.native.rect.height / 4].min

        perform_native_drag(source: handle, target:, offset_y: offset_y.round)

        # Assert Pragmatic DnD tore down its own honey-pot overlay, so a regression
        # leaving it stuck is caught here rather than as an unrelated click failure.
        expect(page).to have_no_css("[data-pdnd-honey-pot]", wait: 2, visible: :all)
      end

      private

      def row(record)
        within_list { find(item_selector, record.name) }
      end

      def drag_handle(record)
        row(record).find(:button, accessible_name: I18n.t("drag_handle.button_drag"))
      end

      def open_controlled_menu(button)
        button.click
        page.find(:menu, id: button["aria-controls"])
      end
    end
  end
end

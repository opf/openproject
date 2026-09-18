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

# Menu and ordering helpers for the enumeration admin lists (priorities,
# time entry activities, document types). Included per feature spec.
# Consumers define `enumeration_list_selector` and `enumeration_actions_label`;
# tables override `enumeration_item_selector` with `:row`.
module EnumerationAdminHelpers
  def enumeration_item_selector = :list_item

  def within_enumeration_list(&)
    page.within(enumeration_list_selector, &)
  end

  def expect_enumeration_order(*names)
    within_enumeration_list do
      expect(page).to have_selector(enumeration_item_selector, count: names.size)
      names.each_with_index do |name, index|
        expect(page).to have_selector(enumeration_item_selector, name, position: index + 1)
      end
    end
  end

  def expect_enumeration_move_settled(*names)
    expect_and_dismiss_flash(message: I18n.t(:enumeration_caption_order_changed))
    expect_enumeration_order(*names)
    expect(page).to have_no_css("[data-sortable-lists-busy]")
  end

  def within_enumeration_menu(record, &)
    within_enumeration_list do
      within(enumeration_item_selector, record.name) do
        button = find(:button, accessible_name: enumeration_actions_label)
        within(open_controlled_menu(button), &)
      end
    end
  end

  def within_enumeration_move_submenu(record, &)
    within_enumeration_menu(record) do |menu|
      within(open_controlled_menu(menu.find(:menuitem, I18n.t(:button_move))), &)
    end
  end

  def move_enumeration(record, direction_label)
    within_enumeration_move_submenu(record) do |submenu|
      submenu.find(:menuitem, direction_label).click
    end
  end

  def enumeration_drag_handle(record)
    within_enumeration_list do
      find(enumeration_item_selector, record.name)
        .find(:button, accessible_name: I18n.t("drag_handle.button_drag"))
    end
  end

  def enumeration_row(record)
    within_enumeration_list { find(enumeration_item_selector, record.name) }
  end

  private

  def open_controlled_menu(button)
    button.click
    page.find(:menu, id: button["aria-controls"])
  end
end

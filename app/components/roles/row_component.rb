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

module Roles
  class RowComponent < OpPrimer::BorderBoxRowComponent
    alias_method :role, :model

    def row_css_id
      "role-#{role.id}"
    end

    def name
      link = render(Primer::Beta::Link.new(href: edit_role_path(role), font_weight: :bold)) { role.name }

      role.builtin? ? tag.em { link } : link
    end

    def global
      return unless role.is_a?(GlobalRole)

      render(Primer::Beta::Octicon.new(icon: :check, test_selector: "role-global-checkmark"))
    end

    def button_links
      [action_menu]
    end

    private

    def action_menu
      render(Primer::Alpha::ActionMenu.new(test_selector: "role-action-menu")) do |menu|
        menu.with_show_button(
          scheme: :invisible,
          size: :small,
          icon: :"kebab-horizontal",
          "aria-label": t(:button_actions),
          tooltip_direction: :w
        )

        edit_action(menu)

        unless role.builtin?
          move_action(menu) if movable?
          menu.with_divider
          delete_action(menu)
        end
      end
    end

    def edit_action(menu)
      menu.with_item(label: t(:button_edit), href: edit_role_path(role)) do |item|
        item.with_leading_visual_icon(icon: :pencil)
      end
    end

    def movable?
      !(first? && last?)
    end

    def first?
      role.position == table.first_movable_position
    end

    def last?
      role.position == table.last_movable_position
    end

    def move_action(menu)
      menu.with_item(
        component_klass: Primer::Alpha::ActionMenu::SubMenuItem,
        label: t(:button_move),
        select_variant: :none,
        form_arguments: {}
      ) do |submenu|
        submenu.with_leading_visual_icon(icon: :"op-arrow-in")

        unless first?
          move_item(submenu, "highest", t(:label_sort_highest), "move-to-top")
          move_item(submenu, "higher", t(:label_sort_higher), "chevron-up")
        end

        unless last?
          move_item(submenu, "lower", t(:label_sort_lower), "chevron-down")
          move_item(submenu, "lowest", t(:label_sort_lowest), "move-to-bottom")
        end
      end
    end

    def move_item(submenu, move_to, label, icon)
      submenu.with_item(
        label:,
        href: role_path(role, role: { move_to: }),
        form_arguments: { method: :put }
      ) do |item|
        item.with_leading_visual_icon(icon:)
      end
    end

    def delete_action(menu)
      menu.with_item(
        label: t(:button_delete),
        scheme: :danger,
        href: role_path(role),
        form_arguments: { method: :delete, data: { turbo_confirm: t(:text_are_you_sure) } }
      ) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end
  end
end

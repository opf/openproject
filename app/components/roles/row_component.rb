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
    MOVE_ITEMS = [
      { label: :label_sort_highest, direction: "top", icon: :"move-to-top" },
      { label: :label_sort_higher, direction: "up", icon: :"chevron-up" },
      { label: :label_sort_lower, direction: "down", icon: :"chevron-down" },
      { label: :label_sort_lowest, direction: "bottom", icon: :"move-to-bottom" }
    ].freeze

    alias_method :role, :model

    def row_css_id
      "role-#{role.id}"
    end

    def row_data
      return {} unless reorderable?

      {
        controller: "sortable-lists--item",
        # The row is its own preview target, so the drag image is the whole row.
        sortable_lists__item_target: "preview",
        sortable_lists__item_id_value: role.id,
        sortable_lists__item_type_value: Role::SORTABLE_LIST_TYPE,
        sortable_lists__item_label_value: role.name
      }
    end

    def name
      flex_layout(align_items: :center) do |flex|
        flex.with_column(mr: 2) { drag_handle }
        flex.with_column { name_link }
      end
    end

    def global
      return unless role.is_a?(GlobalRole)

      render(Primer::Beta::Octicon.new(icon: :check, test_selector: "role-global-checkmark"))
    end

    def permissions_count
      render(Primer::Beta::Text.new(color: :subtle, test_selector: "role-permissions-count")) do
        role.permissions.size.to_s
      end
    end

    def button_links
      [action_menu]
    end

    private

    def reorderable?
      !role.builtin?
    end

    def name_link
      link = render(Primer::Beta::Link.new(href: edit_role_path(role), font_weight: :bold)) { role.name }

      role.builtin? ? tag.em { link } : link
    end

    # Builtin roles always sort after the reorderable ones, so they get a spacer keeping
    # their name aligned with the rest of the column instead of a handle.
    def drag_handle
      if reorderable?
        render(Primer::OpenProject::DragHandle.new(data: { sortable_lists__item_target: "handle" }))
      else
        render(Primer::Box.new(classes: "hide-when-print", style: "width: 16px"))
      end
    end

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

        if reorderable?
          move_action(menu)
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

    def move_action(menu)
      menu.with_item(
        component_klass: Primer::Alpha::ActionMenu::SubMenuItem,
        label: t(:button_move),
        select_variant: :none,
        form_arguments: {},
        data: { sortable_lists__item_target: "moveMenu" }
      ) do |submenu|
        submenu.with_leading_visual_icon(icon: :"op-arrow-in")

        MOVE_ITEMS.each { move_item(submenu, **it) }
      end
    end

    # The `data:` hash must live on the item level so Primer renders it on the ActionList
    # `<li>`, which is what the item controller targets to compute availability and to
    # handle the bubbled click.
    def move_item(submenu, label:, direction:, icon:)
      submenu.with_item(
        label: I18n.t(label),
        tag: :button,
        data: {
          sortable_lists__item_target: "moveItem",
          sortable_lists__item_direction_param: direction,
          action: "click->sortable-lists--item#move"
        }
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

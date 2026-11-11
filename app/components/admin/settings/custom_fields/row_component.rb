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

module Admin
  module Settings
    module CustomFields
      class RowComponent < OpPrimer::BorderBoxRowComponent
        include SortableLists::MoveMenu

        def custom_field
          row
        end

        def row_css_id
          "custom-field-#{custom_field.id}"
        end

        def row_data
          return {} unless movable?

          {
            controller: "sortable-lists--item",
            sortable_lists__item_target: "preview",
            sortable_lists__item_id_value: custom_field.id,
            sortable_lists__item_type_value: CustomField::SORTABLE_LIST_TYPE,
            sortable_lists__item_label_value: custom_field.name
          }
        end

        def name
          flex_layout(align_items: :center) do |flex|
            flex.with_column(mr: 2) { drag_handle } if movable?
            flex.with_column { name_link }
          end
        end

        def field_format
          helpers.label_for_custom_field_format(custom_field.field_format)
        end

        def is_required # rubocop:disable Naming/PredicatePrefix
          checkmark(custom_field.is_required?)
        end

        def used_in_projects
          reach = table.project_counts[custom_field.id].to_i
          label = t(:label_x_projects, count: reach)

          reach.zero? ? warning(label) : label
        end

        def contained_in_type
          type_links = variant_links

          if type_links.empty?
            warning(render(Primer::Beta::Link.new(href: types_path)) { t(:label_custom_field_add_no_type) })
          else
            render(OpPrimer::ExpandableTextComponent.new) { safe_join(type_links, ", ") }
          end
        end

        def button_links
          movable? ? [action_menu] : [delete_button]
        end

        private

        def variant_links
          custom_field.type_variants.map do |variant|
            render(Primer::Beta::Link.new(href: helpers.edit_variant_form_configuration_path(nil, variant))) do
              variant.composite_name
            end
          end
        end

        def movable?
          table.reorderable?
        end

        def delete_button
          render(Primer::Beta::IconButton.new(
                   tag: :a,
                   href: helpers.deletion_dialog_path(custom_field),
                   data: { controller: "async-dialog" },
                   aria: { label: t(:button_delete) },
                   icon: :trash,
                   scheme: :danger,
                   size: :small,
                   test_selector: "custom-field-delete-button"
                 ))
        end

        def name_link
          render(Primer::Beta::Link.new(href: helpers.edit_path(custom_field),
                                        font_weight: :bold,
                                        lang: custom_field.name_locale)) { custom_field.name }
        end

        def drag_handle
          render(Primer::OpenProject::DragHandle.new(data: { sortable_lists__item_target: "handle" }))
        end

        def warning(content)
          flex_layout(align_items: :center) do |flex|
            flex.with_column(mr: 1) do
              render(Primer::Beta::Octicon.new(icon: :alert, color: :attention))
            end
            flex.with_column { content }
          end
        end

        def action_menu
          render(Primer::Alpha::ActionMenu.new(test_selector: "custom-field-action-menu")) do |menu|
            menu.with_show_button(
              scheme: :invisible,
              size: :small,
              icon: :"kebab-horizontal",
              "aria-label": t(:button_actions),
              tooltip_direction: :w
            )

            edit_action(menu)
            with_move_submenu(menu)

            menu.with_divider
            delete_action(menu)
          end
        end

        def edit_action(menu)
          menu.with_item(label: t(:button_edit), href: helpers.edit_path(custom_field)) do |item|
            item.with_leading_visual_icon(icon: :pencil)
          end
        end

        def delete_action(menu)
          menu.with_item(
            label: t(:button_delete),
            scheme: :danger,
            href: helpers.deletion_dialog_path(custom_field),
            content_arguments: { data: { controller: "async-dialog" } }
          ) do |item|
            item.with_leading_visual_icon(icon: :trash)
          end
        end
      end
    end
  end
end

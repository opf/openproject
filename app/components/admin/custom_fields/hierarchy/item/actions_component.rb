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

module Admin
  module CustomFields
    module Hierarchy
      module Item
        class ActionsComponent < ApplicationComponent
          include OpPrimer::ComponentHelpers

          def initialize(item)
            super

            @root = item.root
          end

          def menu_id
            ItemComponent.menu_id(item:)
          end

          def menu_items(menu) # rubocop:disable Metrics/AbcSize
            with_item_group(menu) { edit_action_item(menu) }

            with_item_group(menu) do
              add_above_action_item(menu)
              add_below_action_item(menu)
              add_sub_item_action_item(menu)
            end

            with_item_group(menu) { default_action_item(menu) }

            with_item_group(menu) { change_parent_item(menu) }

            with_item_group(menu) do
              unless first_item?
                move_to_top_action_item(menu)
                move_up_action_item(menu)
              end
              unless last_item?
                move_down_action_item(menu)
                move_to_bottom_action_item(menu)
              end
            end

            with_item_group(menu) { deletion_action_item(menu) }
          end

          private

          alias_method :item, :model

          def first_item?
            item.sort_order == 0
          end

          def last_item?
            item.sort_order == item.parent.children.length - 1
          end

          def project_custom_field_context?
            @root.custom_field.is_a?(ProjectCustomField)
          end

          def custom_field_id = @root.custom_field_id

          def edit_action_item(menu)
            href = if project_custom_field_context?
                     edit_admin_settings_project_custom_field_item_path(custom_field_id, item)
                   else
                     edit_custom_field_item_path(custom_field_id, item)
                   end

            menu.with_item(label: I18n.t(:button_edit), tag: :a, href:) do |item|
              item.with_leading_visual_icon(icon: :pencil)
            end
          end

          def add_above_action_item(menu)
            parent = item.parent
            position = item.sort_order
            href = if project_custom_field_context?
                     new_child_admin_settings_project_custom_field_item_path(custom_field_id, parent, position:)
                   else
                     new_child_custom_field_item_path(custom_field_id, parent, position:)
                   end

            menu.with_item(
              label: I18n.t(:button_add_item_above),
              tag: :a,
              href:,
              content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } }
            ) { it.with_leading_visual_icon(icon: "fold-up") }
          end

          def add_below_action_item(menu)
            parent = item.parent
            position = item.sort_order + 1
            href = if project_custom_field_context?
                     new_child_admin_settings_project_custom_field_item_path(custom_field_id, parent, position:)
                   else
                     new_child_custom_field_item_path(custom_field_id, parent, position:)
                   end

            menu.with_item(
              label: I18n.t(:button_add_item_below),
              tag: :a,
              href:,
              content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } }
            ) { it.with_leading_visual_icon(icon: "fold-down") }
          end

          def add_sub_item_action_item(menu)
            children = item.children
            position = children.any? ? children.maximum(:sort_order) + 1 : 0
            href = if project_custom_field_context?
                     new_child_admin_settings_project_custom_field_item_path(custom_field_id, item, position:)
                   else
                     new_child_custom_field_item_path(custom_field_id, item, position:)
                   end

            menu.with_item(
              label: I18n.t(:button_add_sub_item),
              tag: :a,
              href:,
              content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } }
            ) { it.with_leading_visual_icon(icon: "op-arrow-in") }
          end

          def default_action_item(menu)
            label = item.default_value ? I18n.t(:button_clear_default_value) : I18n.t(:button_set_as_default_value)
            action = item.default_value ? :clear_default : :set_default
            href = if project_custom_field_context?
                     send(:"#{action}_admin_settings_project_custom_field_item_path", custom_field_id, item)
                   else
                     send(:"#{action}_custom_field_item_path", custom_field_id, item)
                   end

            menu.with_item(label:, tag: :a, href:, content_arguments: { data: { turbo_method: :post } }) do |entry|
              entry.with_leading_visual_icon(icon: :check)
            end
          end

          def change_parent_item(menu)
            href = if project_custom_field_context?
                     change_parent_admin_settings_project_custom_field_item_path(project_custom_field_id: custom_field_id,
                                                                                 id: item.id)
                   else
                     change_parent_custom_field_item_path(custom_field_id:, id: item.id)
                   end

            menu.with_item(
              label: I18n.t(:label_change_parent),
              tag: :a,
              href:,
              content_arguments: { data: { controller: "async-dialog" } }
            ) { it.with_leading_visual_icon(icon: "arrow-switch") }
          end

          def move_to_top_action_item(menu)
            form_inputs = [{ name: "new_sort_order", value: 0 }]
            href = if project_custom_field_context?
                     move_admin_settings_project_custom_field_item_path(custom_field_id, item)
                   else
                     move_custom_field_item_path(custom_field_id, item)
                   end

            menu.with_item(label: I18n.t(:label_sort_highest),
                           tag: :button,
                           href:,
                           content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } },
                           form_arguments: { method: :post, inputs: form_inputs }) do |item|
              item.with_leading_visual_icon(icon: "move-to-top")
            end
          end

          def move_up_action_item(menu)
            form_inputs = [{ name: "new_sort_order", value: item.sort_order - 1 }]
            href = if project_custom_field_context?
                     move_admin_settings_project_custom_field_item_path(custom_field_id, item)
                   else
                     move_custom_field_item_path(custom_field_id, item)
                   end

            menu.with_item(label: I18n.t(:label_sort_higher),
                           tag: :button,
                           href:,
                           content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } },
                           form_arguments: { method: :post, inputs: form_inputs }) do |item|
              item.with_leading_visual_icon(icon: "chevron-up")
            end
          end

          def move_down_action_item(menu)
            form_inputs = [{ name: "new_sort_order", value: item.sort_order + 2 }]
            href = if project_custom_field_context?
                     move_admin_settings_project_custom_field_item_path(custom_field_id, item)
                   else
                     move_custom_field_item_path(custom_field_id, item)
                   end

            menu.with_item(label: I18n.t(:label_sort_lower),
                           tag: :button,
                           href:,
                           content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } },
                           form_arguments: { method: :post, inputs: form_inputs }) do |item|
              item.with_leading_visual_icon(icon: "chevron-down")
            end
          end

          def move_to_bottom_action_item(menu)
            form_inputs = [{ name: "new_sort_order", value: item.parent.children.length + 1 }]
            href = if project_custom_field_context?
                     move_admin_settings_project_custom_field_item_path(custom_field_id, item)
                   else
                     move_custom_field_item_path(custom_field_id, item)
                   end

            menu.with_item(label: I18n.t(:label_sort_lowest),
                           tag: :button,
                           href:,
                           content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } },
                           form_arguments: { method: :post, inputs: form_inputs }) do |item|
              item.with_leading_visual_icon(icon: "move-to-bottom")
            end
          end

          def deletion_action_item(menu)
            href = if project_custom_field_context?
                     delete_admin_settings_project_custom_field_item_path(project_custom_field_id: custom_field_id,
                                                                          id: item.id)
                   else
                     delete_custom_field_item_path(custom_field_id:, id: item.id)
                   end

            menu.with_item(label: I18n.t(:button_delete),
                           scheme: :danger,
                           tag: :a,
                           href:,
                           content_arguments: { data: { controller: "async-dialog" } }) do |item|
              item.with_leading_visual_icon(icon: :trash)
            end
          end
        end
      end
    end
  end
end

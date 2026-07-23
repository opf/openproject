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

module WorkPackageTypes
  module Types
    class GroupedListComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      def initialize(types:, expanded_type_id: nil)
        super()

        @types = types
        @expanded_type_id = expanded_type_id
      end

      private

      attr_reader :types, :expanded_type_id

      def collapsed?(root)
        root.id != expanded_type_id
      end

      def variants_count_label(root)
        t("types.index.variants_count", count: root.children.size)
      end

      # A default variant is only visible once the group is expanded, so the
      # collapsed header names it instead.
      def default_label(root)
        if root.is_default?
          { scheme: :default, text: t("types.index.enabled_in_new_projects") }
        elsif (variant = default_variant(root))
          { scheme: :secondary, text: t("types.index.variant_enabled_in_new_projects", name: variant.own_name) }
        end
      end

      def default_variant(root)
        root.children.find(&:is_default?)
      end

      def add_variant_path(root)
        new_creation_wizard_types_path(parent_id: root.id)
      end

      def type_actions(menu, type)
        configure_action(menu, type)
        default_action(menu, type)
        menu.with_divider

        if reorderable?(type)
          move_action(menu, type)
          menu.with_divider
        end

        delete_action(menu, type)
      end

      def configure_action(menu, type)
        menu.with_item(label: t(:button_configure), href: edit_type_details_path(type_id: type.id)) do |item|
          item.with_leading_visual_icon(icon: :gear)
        end
      end

      def default_action(menu, type)
        if type.is_default?
          remove_default_action(menu, type)
        else
          make_default_action(menu, type)
        end
      end

      def make_default_action(menu, type)
        menu.with_item(
          label: t("types.index.make_default"),
          href: make_default_type_path(type),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon: :"check-circle")
        end
      end

      def remove_default_action(menu, type)
        menu.with_item(
          label: t("types.index.remove_default"),
          href: remove_default_type_path(type),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon: :"circle-slash")
        end
      end

      def delete_action(menu, type)
        menu.with_item(
          label: t(:button_delete),
          scheme: :danger,
          href: type_path(type),
          form_arguments: { method: :delete, data: { turbo_confirm: t(:text_are_you_sure) } }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def reorderable?(type)
        !type.variant? && !(type.first? && type.last?)
      end

      def move_action(menu, type)
        menu.with_sub_menu_item(label: t(:button_move)) do |submenu|
          submenu.with_leading_visual_icon(icon: :"op-arrow-in")

          unless type.first?
            move_item(submenu, type, :highest, t(:label_sort_highest), "move-to-top")
            move_item(submenu, type, :higher, t(:label_sort_higher), "chevron-up")
          end

          unless type.last?
            move_item(submenu, type, :lower, t(:label_sort_lower), "chevron-down")
            move_item(submenu, type, :lowest, t(:label_sort_lowest), "move-to-bottom")
          end
        end
      end

      def move_item(submenu, type, move_to, label, icon)
        submenu.with_item(
          label:,
          href: helpers.url_for(action: :move, id: type.id, type: { move_to: }),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon:)
        end
      end

      def drop_target_config
        {
          generic_drag_and_drop_target: "container",
          "target-allowed-drag-type": "work-package-type"
        }
      end

      def draggable_item_config(root)
        {
          "draggable-type": "work-package-type",
          "draggable-id": root.id,
          "drop-url": drop_type_path(root)
        }
      end

      # variants need to be displayed alphabetically sorted
      def sorted_children(root)
        root.children.sort_by { |child| child.own_name.downcase }
      end
    end
  end
end

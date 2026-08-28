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
    class TypeActionsComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers

      def self.menu_id(type)
        "type-#{type.id}-action-menu"
      end

      def initialize(type:)
        super()

        @type = type
      end

      def menu_id
        self.class.menu_id(type)
      end

      private

      attr_reader :type

      def type_actions(menu)
        configure_action(menu)
        default_action(menu)
        menu.with_divider

        add_variant_action(menu)
        duplicate_action(menu)
        menu.with_divider

        if reorderable?
          move_action(menu)
          menu.with_divider
        end

        delete_action(menu) unless type.builtin?
      end

      def add_variant_action(menu)
        menu.with_item(label: t("types.index.add_variant_action"),
                       href: new_creation_wizard_types_path(type_id: type.id, back_url: types_path)) do |item|
          item.with_leading_visual_icon(icon: :plus)
        end
      end

      def duplicate_action(menu)
        menu.with_item(
          label: t(:button_duplicate),
          href: duplicate_type_path(type),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon: :duplicate)
        end
      end

      def configure_action(menu)
        menu.with_item(label: t(:button_configure), href: edit_type_details_path(type_id: type.id)) do |item|
          item.with_leading_visual_icon(icon: :gear)
        end
      end

      # The flag lives on the configuration a project applies the type through, and this menu
      # acts on the type as a whole, so it toggles the base variant.
      def default_variant
        type.default_variant
      end

      def default_action(menu)
        if default_variant.enabled_in_new_projects?
          remove_default_action(menu)
        else
          make_default_action(menu)
        end
      end

      def make_default_action(menu)
        menu.with_item(
          label: t("types.index.make_default"),
          href: make_default_type_variant_path(type_id: type.id, id: default_variant.id),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon: :"check-circle")
        end
      end

      def remove_default_action(menu)
        menu.with_item(
          label: t("types.index.remove_default"),
          href: remove_default_type_variant_path(type_id: type.id, id: default_variant.id),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon: :"circle-slash")
        end
      end

      def delete_action(menu)
        menu.with_item(
          label: t(:button_delete),
          scheme: :danger,
          href: type_path(type),
          form_arguments: { method: :delete, data: { turbo_confirm: t(:text_are_you_sure) } }
        ) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end

      def reorderable?
        !(type.first? && type.last?)
      end

      def move_action(menu)
        menu.with_item(
          component_klass: Primer::Alpha::ActionMenu::SubMenuItem,
          label: t(:button_move),
          select_variant: :none,
          form_arguments: {}
        ) do |submenu|
          submenu.with_leading_visual_icon(icon: :"op-arrow-in")

          unless type.first?
            move_item(submenu, :highest, t(:label_sort_highest), "move-to-top")
            move_item(submenu, :higher, t(:label_sort_higher), "chevron-up")
          end

          unless type.last?
            move_item(submenu, :lower, t(:label_sort_lower), "chevron-down")
            move_item(submenu, :lowest, t(:label_sort_lowest), "move-to-bottom")
          end
        end
      end

      def move_item(submenu, move_to, label, icon)
        submenu.with_item(
          label:,
          href: move_types_path(type, type: { move_to: }),
          form_arguments: { method: :post }
        ) do |item|
          item.with_leading_visual_icon(icon:)
        end
      end
    end
  end
end

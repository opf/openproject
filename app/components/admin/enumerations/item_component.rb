# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2024 the OpenProject GmbH
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
# ++

module Admin
  module Enumerations
    class ItemComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable
      include SortableLists::MoveMenu

      options :enumeration

      delegate :colored?, to: :enumeration

      private

      def wrapper_uniq_by
        enumeration.id
      end

      def build_enumeration_menu(menu)
        with_item_group(menu) do
          edit_enumeration(menu)
          move_enumeration(menu)
        end
        with_item_group(menu) { deletion_enumeration(menu) }
      end

      def edit_enumeration(menu)
        menu.with_item(label: I18n.t(:button_edit),
                       tag: :a,
                       href: helpers.url_for(action: :edit, id: enumeration)) do |item|
          item.with_leading_visual_icon(icon: :pencil)
        end
      end

      def move_enumeration(menu)
        menu.with_item(
          component_klass: Primer::Alpha::ActionMenu::SubMenuItem,
          label: I18n.t(:button_move),
          select_variant: :none,
          form_arguments: {},
          data: { sortable_lists__item_target: "moveMenu" }
        ) do |submenu|
          submenu.with_leading_visual_icon(icon: :"op-arrow-in")

          with_move_items(submenu)
        end
      end

      def deletion_enumeration(menu)
        menu.with_item(label: I18n.t(:button_delete),
                       tag: :button,
                       scheme: :danger,
                       href: helpers.url_for(action: :destroy, id: enumeration),
                       form_arguments: { method: :delete }) do |item|
          item.with_leading_visual_icon(icon: :trash)
        end
      end
    end
  end
end

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

      options :enumeration
      options :max_position

      delegate :colored?, to: :enumeration

      private

      def wrapper_uniq_by
        enumeration.id
      end

      def first_item?
        enumeration.position == 1
      end

      def last_item?
        enumeration.position == max_position
      end

      def build_enumeration_menu(menu)
        with_item_group(menu) { edit_enumeration(menu) }
        with_item_group(menu) do
          unless first_item?
            move_to_top_enumeration(menu)
            move_up_enumeration(menu)
          end
          unless last_item?
            move_down_enumeration(menu)
            move_to_bottom_enumeration(menu)
          end
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

      def move_to_top_enumeration(menu)
        form_inputs = [{ name: "move_to", value: "highest" }]

        menu.with_item(label: I18n.t(:label_sort_highest),
                       tag: :button,
                       href: helpers.url_for(action: :move, id: enumeration),
                       # content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } },
                       form_arguments: { method: :put, inputs: form_inputs }) do |item|
          item.with_leading_visual_icon(icon: "move-to-top")
        end
      end

      def move_up_enumeration(menu)
        form_inputs = [{ name: "move_to", value: "higher" }]

        menu.with_item(label: I18n.t(:label_sort_higher),
                       tag: :button,
                       href: helpers.url_for(action: :move, id: enumeration),
                       # content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } },
                       form_arguments: { method: :put, inputs: form_inputs }) do |item|
          item.with_leading_visual_icon(icon: "chevron-up")
        end
      end

      def move_down_enumeration(menu)
        form_inputs = [{ name: "move_to", value: "lower" }]

        menu.with_item(label: I18n.t(:label_sort_lower),
                       tag: :button,
                       href: helpers.url_for(action: :move, id: enumeration),
                       #  content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } },
                       form_arguments: { method: :put, inputs: form_inputs }) do |item|
          item.with_leading_visual_icon(icon: "chevron-down")
        end
      end

      def move_to_bottom_enumeration(menu)
        form_inputs = [{ name: "move_to", value: "lowest" }]

        menu.with_item(label: I18n.t(:label_sort_lowest),
                       tag: :button,
                       href: helpers.url_for(action: :move, id: enumeration),
                       #    content_arguments: { data: { turbo_frame: ItemsComponent.wrapper_key } },
                       form_arguments: { method: :put, inputs: form_inputs }) do |item|
          item.with_leading_visual_icon(icon: "move-to-bottom")
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

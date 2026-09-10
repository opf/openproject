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
  module TextTransformActions
    class RowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      MOVE_ITEMS = [
        { label: :label_sort_highest, direction: "top", icon: :"move-to-top" },
        { label: :label_sort_higher, direction: "up", icon: :"chevron-up" },
        { label: :label_sort_lower, direction: "down", icon: :"chevron-down" },
        { label: :label_sort_lowest, direction: "bottom", icon: :"move-to-bottom" }
      ].freeze

      options toggles_enabled: true

      alias_method :text_transform_action, :model

      def wrapper_uniq_by
        text_transform_action.id
      end

      private

      def scope_text
        if text_transform_action.specific_work_package_types?
          t(".scope_specific_work_package_types", count: text_transform_action.types.size)
        else
          t("admin.text_transform_actions.usage_scopes.#{text_transform_action.usage_scope}")
        end
      end

      def toggle_label
        t(".label_toggle", label: text_transform_action.label)
      end

      # The `data:` hash must live on the item level so Primer renders it on
      # the ActionList `<li>`, which is what the sortable-lists item controller
      # targets to compute availability and to handle the bubbled click.
      def build_move_item(menu, label:, direction:, icon:)
        menu.with_item(
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
    end
  end
end

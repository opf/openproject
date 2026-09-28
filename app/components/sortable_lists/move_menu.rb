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

module SortableLists
  module MoveMenu
    Direction = Data.define(:label, :direction, :icon) do
      def item_data
        {
          sortable_lists__item_target: "moveItem",
          sortable_lists__item_direction_param: direction,
          action: "click->sortable-lists--item#move"
        }
      end
    end

    DIRECTIONS = [
      Direction.new(label: :label_sort_highest, direction: "top", icon: :"move-to-top"),
      Direction.new(label: :label_sort_higher, direction: "up", icon: :"chevron-up"),
      Direction.new(label: :label_sort_lower, direction: "down", icon: :"chevron-down"),
      Direction.new(label: :label_sort_lowest, direction: "bottom", icon: :"move-to-bottom")
    ].freeze

    private

    # The `data:` hash must live on the item level so Primer renders it on the ActionList
    # `<li>`, which is what the item controller targets to compute availability and to
    # handle the bubbled click.
    def with_move_items(menu)
      DIRECTIONS.each do |move|
        menu.with_item(label: I18n.t(move.label), tag: :button, data: move.item_data) do |item|
          item.with_leading_visual_icon(icon: move.icon)
        end
      end
    end
  end
end

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
  # Shared vocabulary and rendering for the four-direction move items every
  # sortable-lists consumer offers (#DREAM-775).
  #
  # `move_to:` carries the acts_as_list value surfaces that still persist
  # server-side build their hrefs from; each drops it on moving to `prev_id`.
  class MoveMenuItems
    include ActionView::RecordIdentifier

    DIRECTIONS = [
      { direction: :top, label: :label_sort_highest, icon: :"move-to-top", move_to: :highest }.freeze,
      { direction: :up, label: :label_sort_higher, icon: :"chevron-up", move_to: :higher }.freeze,
      { direction: :down, label: :label_sort_lower, icon: :"chevron-down", move_to: :lower }.freeze,
      { direction: :bottom, label: :label_sort_lowest, icon: :"move-to-bottom", move_to: :lowest }.freeze
    ].freeze

    def initialize(dom_key:)
      @dom_key = dom_key
    end

    def render_into(menu)
      DIRECTIONS.each { |entry| add_item(menu, entry) }
    end

    private

    attr_reader :dom_key

    def add_item(menu, entry)
      direction = entry[:direction]

      # The `data:` hash must live at item level so Primer renders it on the
      # ActionList `<li>`: the controller's targets and the action-menu API's
      # `disableItem`/`enableItem` both address that element, and the click
      # action rides it via the bubbled button click.
      menu.with_item(
        id: dom_target(dom_key, :menu, direction),
        label: I18n.t(entry[:label]),
        tag: :button,
        data: {
          sortable_lists__item_target: "moveItem",
          sortable_lists__item_direction_param: direction,
          action: "click->sortable-lists--item#move"
        }
      ) do |item|
        item.with_leading_visual_icon(icon: entry[:icon])
      end
    end
  end
end

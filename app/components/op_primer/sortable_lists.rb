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

module OpPrimer
  # Value objects owning the Stimulus `sortable-lists` wiring contract.
  #
  # Inspired by LiveComponent's `Target`/`Action` shape: frozen value objects
  # (`Data.define`) that close over the controller identifier and emit `data`
  # attributes, so components declare drag-and-drop intent instead of
  # hand-writing `sortable_lists__*` keys. Emission-only — the Stimulus
  # suite under `frontend/src/stimulus/controllers/dynamic/sortable-lists`
  # remains the behavioral contract, and new controller values must be
  # added here deliberately. Unknown keys raise, preventing typo'd keys
  # from emitting inert attributes Stimulus silently ignores.
  module SortableLists
    ITEM_CONTROLLER = "sortable-lists--item"
    LIST_CONTROLLER = "sortable-lists--list"

    # Wiring for an element whose children are sortable rows.
    List = Data.define(:type, :accepted_type, :id, :name, :drop_position) do
      # @param record [Object] source for `id`/`name` (`record.try(:name)`
      #   falling back to `record.to_s`). The wire `type:` is never derived:
      #   wire types are short names keyed into the root's URL template map.
      def self.for(record, type:, **overrides)
        new(type:, id: record.id, name: record.try(:name) || record.to_s, **overrides)
      end

      def initialize(type:, accepted_type: nil, id: nil, name: nil, drop_position: nil)
        raise ArgumentError, "type is required" if type.blank?

        super(type:, accepted_type: accepted_type || type, id:, name:, drop_position:)
      end

      # @return [Hash] Stimulus data attributes for the list element.
      def to_data
        {
          controller: LIST_CONTROLLER,
          sortable_lists__list_type_value: type,
          sortable_lists__list_accepted_type_value: accepted_type,
          sortable_lists__list_id_value: id,
          sortable_lists__list_name_value: name,
          sortable_lists__list_drop_position_value: drop_position
        }.compact
      end
    end

    # Wiring for a draggable element.
    Item = Data.define(:id, :type, :label, :targets, :confined, :external_url, :hide_unavailable) do
      # @param record [Object] source for `id`/`label`. `type:` is never
      #   derived — see {List.for}.
      def self.for(record, type:, **overrides)
        new(
          type:,
          id: record.id,
          label: record.try(:name) || record.to_s,
          **overrides
        )
      end

      def initialize(id:, type:, label: nil, targets: [], confined: nil, external_url: nil, hide_unavailable: nil)
        raise ArgumentError, "id is required" if id.blank?
        raise ArgumentError, "type is required" if type.blank?

        normalized_targets = Set.new(Array(targets).map(&:to_s)).freeze
        super(id:, type:, label:, targets: normalized_targets, confined:, external_url:, hide_unavailable:)
      end

      # @return [Item] copy with `extra` targets token-merged and deduplicated.
      def with_targets(*extra)
        with(targets: (targets | extra.map(&:to_s)).freeze)
      end

      # @return [Hash] Stimulus data attributes for the item element.
      def to_data
        {
          controller: ITEM_CONTROLLER,
          sortable_lists__item_id_value: id,
          sortable_lists__item_type_value: type,
          sortable_lists__item_label_value: label,
          sortable_lists__item_confined_value: confined,
          sortable_lists__item_external_url_value: external_url,
          sortable_lists__item_hide_unavailable_value: hide_unavailable,
          sortable_lists__item_target: targets.presence&.join(" ")
        }.compact
      end
    end
  end
end

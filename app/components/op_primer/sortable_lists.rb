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
    ROOT_CONTROLLER = "sortable-lists"
    SCROLLABLE_CONTROLLER = "sortable-lists--scrollable"

    # Marker substituted into `Root`'s lambda-built move URL(s) before being
    # rewritten to the literal `{id}` template placeholder. A dedicated
    # marker (rather than e.g. a numeric sentinel) can't collide with real
    # URL text produced by the route helpers.
    ROOT_ID_SENTINEL = "__sortable_lists_id__"
    # Defensive only: `ERB::Util.url_encode` leaves this sentinel's
    # letters/digits/underscores byte-identical, so today this is the same
    # string as `ROOT_ID_SENTINEL`. Kept distinct (and gsubbed separately in
    # `templatize`) in case a route helper ever percent-encodes it.
    ROOT_ID_SENTINEL_ENCODED = ERB::Util.url_encode(ROOT_ID_SENTINEL)

    ROOT_CHILD_CONTROLLERS = {
      list: LIST_CONTROLLER,
      item: ITEM_CONTROLLER,
      scrollable: SCROLLABLE_CONTROLLER
    }.freeze

    # Accepted `allowed_axis`/`max_scroll_speed` values, mirroring
    # `scrollable.controller.ts`'s `allowedAxes`/`maxScrollSpeeds` sets.
    SCROLLABLE_ALLOWED_AXES = %w[vertical horizontal all].freeze
    SCROLLABLE_MAX_SCROLL_SPEEDS = %w[standard fast].freeze

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

    # Wiring for the page-level element that owns the drag-and-drop root
    # controller, plus its outlet selectors into `List`/`Item`/`Scrollable`
    # children.
    Root = Data.define(:scope_id, :move_url_templates, :move_url_template, :optimistic, :outlets) do
      # @param scope_id [String] id of the element the outlet selectors are
      #   scoped under (usually the root element's own id).
      # @param move_urls [Proc, nil] `->(id)` returning a `{ type => url }`
      #   map; mutually exclusive with `move_url:`.
      # @param move_url [Proc, nil] `->(id)` returning a single url string;
      #   mutually exclusive with `move_urls:`.
      # @param optimistic [Boolean, nil] emits `sortable_lists_optimistic_value`
      #   when set, matching the `optimistic` Stimulus value the root
      #   controller reads to skip its own turbo-stream round trip.
      # @param outlets [Array<Symbol>] child controllers to derive outlet
      #   selectors for; keys of {ROOT_CHILD_CONTROLLERS}.
      def initialize(scope_id:, move_urls: nil, move_url: nil, optimistic: nil, outlets: %i[list item])
        raise ArgumentError, "scope_id is required" if scope_id.blank?
        if move_urls.nil? == move_url.nil?
          raise ArgumentError, "provide exactly one of move_urls or move_url"
        end

        normalized_outlets = Array(outlets).map(&:to_sym).freeze
        unknown_outlets = normalized_outlets - ROOT_CHILD_CONTROLLERS.keys
        if unknown_outlets.any?
          raise ArgumentError, "unknown outlet(s): #{unknown_outlets.join(', ')}"
        end

        super(
          scope_id:,
          move_url_templates: move_urls && build_move_url_templates(move_urls),
          move_url_template: move_url && build_move_url_template(move_url),
          optimistic:,
          outlets: normalized_outlets
        )
      end

      # @return [Hash] Stimulus data attributes for the root element.
      def to_data
        {
          controller: ROOT_CONTROLLER,
          sortable_lists_move_url_templates_value: move_url_templates&.to_json,
          sortable_lists_move_url_template_value: move_url_template,
          sortable_lists_optimistic_value: optimistic,
          **outlet_data
        }.compact
      end

      # @param existing_data [Hash] a plain `data:` hash already used on the
      #   element (e.g. an existing `controller`/`action` pair from another
      #   Stimulus controller). Keys may be Strings or Symbols — both are
      #   recognized against this root's own (Symbol) keys.
      # @return [Hash] a NEW hash: this root's wiring merged in, with
      #   `:controller`/`:action` STRING values token-joined onto the
      #   existing ones (a String-keyed `"controller"`/`"action"` in
      #   `existing_data` is folded into the same canonical Symbol key
      #   rather than left alongside it as a duplicate) and every other
      #   existing key preserved untouched. `existing_data` itself is never
      #   mutated.
      # @raise [ArgumentError] if `existing_data` already hand-wires any of
      #   this root's own keys (other than `:controller`/`:action`), under
      #   either a String or a Symbol key.
      def merge_into(existing_data)
        own = to_data
        reserved = own.keys - %i[controller action]
        conflicting = existing_data.keys.select { |key| reserved.include?(key.to_s.to_sym) }
        raise ArgumentError, "existing data already sets #{conflicting.join(', ')}" if conflicting.any?

        merged = existing_data.dup
        own.each { |key, value| merge_own_key!(merged, key, value) }
        merged
      end

      private

      # Merges one `own.to_data` pair into `merged` (mutated in place).
      # `:controller`/`:action` are folded onto whatever key already carries
      # them in `merged` — String or Symbol — token-joining String values so
      # no duplicate (String- and Symbol-keyed) entry survives; every other
      # key is set directly, since `merge_into`'s conflict check already
      # guarantees no overlap for those.
      def merge_own_key!(merged, key, value)
        return merged[key] = value unless %i[controller action].include?(key)

        existing_key = merged.keys.find { |k| k.to_s.to_sym == key }
        existing_value = existing_key && merged.delete(existing_key)
        merged[key] = existing_value.is_a?(String) ? "#{existing_value} #{value}" : value
      end

      def build_move_url_templates(move_urls)
        raw_map = move_urls.call(ROOT_ID_SENTINEL)
        raise ArgumentError, "move_urls must not be empty" if raw_map.blank?

        raw_map.transform_values do |url|
          unless url.is_a?(String)
            raise ArgumentError, "move_urls values must be Strings (got #{url.class} for #{url.inspect})"
          end

          templatize(url)
        end
      end

      def build_move_url_template(move_url)
        templatize(move_url.call(ROOT_ID_SENTINEL))
      end

      def templatize(built_url)
        raise ArgumentError, "move_url must not be blank" if built_url.blank?

        template = built_url.gsub(ROOT_ID_SENTINEL_ENCODED, "{id}").gsub(ROOT_ID_SENTINEL, "{id}")
        count = template.scan("{id}").length
        case count
        when 0
          raise ArgumentError, "move_url must include the {id} placeholder (got #{template.inspect})"
        when 1
          template
        else
          raise ArgumentError, "move_url must contain exactly one {id} placeholder (got #{count} in #{template.inspect})"
        end
      end

      def outlet_data
        # `outlets` is already validated against ROOT_CHILD_CONTROLLERS in
        # `initialize`, so this fetch cannot raise.
        outlets.to_h do |outlet|
          controller = ROOT_CHILD_CONTROLLERS.fetch(outlet)
          key = :"sortable_lists_#{controller.tr('-', '_')}_outlet"
          [key, "##{scope_id} [data-controller~='#{controller}']"]
        end
      end
    end

    # Wiring for an element that owns the Pragmatic DnD auto-scroll
    # behavior; mirrors the accepted `values` from `scrollable.controller.ts`.
    Scrollable = Data.define(:allowed_axis, :max_scroll_speed) do
      def initialize(allowed_axis: nil, max_scroll_speed: nil)
        if allowed_axis && SCROLLABLE_ALLOWED_AXES.exclude?(allowed_axis)
          raise ArgumentError,
                "allowed_axis must be one of #{SCROLLABLE_ALLOWED_AXES.join(', ')} (got #{allowed_axis.inspect})"
        end
        if max_scroll_speed && SCROLLABLE_MAX_SCROLL_SPEEDS.exclude?(max_scroll_speed)
          raise ArgumentError,
                "max_scroll_speed must be one of #{SCROLLABLE_MAX_SCROLL_SPEEDS.join(', ')} " \
                "(got #{max_scroll_speed.inspect})"
        end

        super
      end

      # @return [Hash] Stimulus data attributes for the scrollable element.
      def to_data
        {
          controller: SCROLLABLE_CONTROLLER,
          sortable_lists__scrollable_allowed_axis_value: allowed_axis,
          sortable_lists__scrollable_max_scroll_speed_value: max_scroll_speed
        }.compact
      end
    end
  end
end

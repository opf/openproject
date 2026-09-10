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

module OpenProject
  module Common
    # A stable-id wrapper that owns the outer sortable-lists region for a page:
    # the drop target for its rows, and — for pages composed of a single
    # collection — the page-level root wiring too.
    #
    # Use this component when a page is a flat collection of rows (e.g. a
    # sections index), or when several `BorderBoxListComponent` boxes need a
    # shared page-level root without any one of them claiming ownership of it.
    # Row content is free-form: unlike `BorderBoxListComponent#with_item`,
    # `with_item_row` does not assume Primer BorderBox row semantics, so a row
    # can itself be a `BorderBoxListComponent` (a dual-role page's per-box
    # list) or any other content.
    class BorderBoxListCollectionComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpPrimer::AttributesHelper

      attr_reader :container

      # Free-form collection row content.
      #
      # @!parse
      #   # Adds a collection row.
      #   #
      #   # @param sortable [OpPrimer::SortableLists::Item, Hash, nil] sortable
      #   #   wiring for this row. A Hash's `type:` defaults from the
      #   #   component's `sortable_list:` accepted type when omitted.
      #   #   Requires the component's `sortable_list:` to be set.
      #   # @param system_arguments [Hash] forwarded to the outer flex row.
      #   # @return [ViewComponent::Slot]
      #   def with_item_row(sortable: nil, **system_arguments, &block)
      #   end
      renders_many :item_rows, ->(sortable: nil, **system_arguments) {
        if sortable
          sortable = coerce_row_sortable(sortable)
          item_data = sortable.to_data
          assert_no_sortable_conflicts!(system_arguments[:data], item_data)
          system_arguments[:data] = merge_data(
            { data: system_arguments[:data] || {} },
            { data: item_data }
          )
        end

        ItemRow.new(**system_arguments)
      }

      # @param container [String, Symbol, Class, Object] value passed to
      #   `dom_target` to derive the wrapper's DOM id. Related sortable-lists
      #   selectors (the root's outlets, an explicit root's `scope_id`) are
      #   derived from the resulting id, not from `container` directly.
      # @param sortable_list [OpPrimer::SortableLists::List, Hash, nil]
      #   sortable wiring for the inner flex container that directly holds
      #   the item rows (not the wrapper — see {#list_container_arguments}),
      #   declaring it as a sortable-lists drop target for its rows. A Hash
      #   is coerced via `OpPrimer::SortableLists::List.new(**hash)`.
      # @param root [true, OpPrimer::SortableLists::Root, nil] page-level
      #   sortable-lists root wiring. `true` derives a
      #   `OpPrimer::SortableLists::Root` scoped to the wrapper's own id, built
      #   from `move_urls:`. An explicit `OpPrimer::SortableLists::Root` is
      #   used as-is once its `scope_id` is confirmed to match the wrapper id
      #   (see {#before_render}) — this is how several boxes composed inside
      #   one collection share a single page-level root without any one box
      #   claiming ownership of it.
      # @param move_urls [Proc, nil] `->(id)` returning a `{ type => url }`
      #   map, forwarded to `OpPrimer::SortableLists::Root` when `root: true`.
      #   Required when `root: true`; ignored otherwise.
      # @param system_arguments [Hash] forwarded to the wrapper element
      #   (`Primer::Box`). Pass `id:` to override the derived wrapper id.
      def initialize(container:, sortable_list: nil, root: nil, move_urls: nil, **system_arguments)
        super()

        @container = container
        @sortable_list = coerce_sortable(sortable_list, OpPrimer::SortableLists::List)
        @root_option = root
        @move_urls = move_urls
        @system_arguments = system_arguments
        @system_arguments[:id] ||= dom_target(container)
        @wrapper_id = @system_arguments[:id]
      end

      def before_render
        content

        @root = resolve_root!
        configure_root_wiring!
      end

      private

      # System arguments for the inner flex container whose direct children
      # are the item rows. Kept a separate element from the wrapper — rather
      # than merging `sortable_list:`'s `data:` onto the wrapper itself —
      # because the wrapper also carries the page-level `root:` wiring when
      # set, and the root's outlet selectors are plain CSS descendant
      # combinators (`##{wrapper_id} [data-controller~='...']`), which by the
      # DOM spec can never match the wrapper element they are scoped from.
      # Mounting the list role on the wrapper would make it invisible to the
      # root's own outlets; mounting it here, on a genuine descendant, keeps
      # it reachable.
      #
      # @return [Hash] forwarded to the inner `Primer::Box`.
      def list_container_arguments
        system_arguments = { display: :flex, direction: :column }
        return system_arguments unless @sortable_list

        system_arguments[:data] = @sortable_list.to_data
        system_arguments
      end

      # @return [OpPrimer::SortableLists::Root, nil]
      # @raise [ArgumentError] if `root: true` is given without `move_urls:`,
      #   if an explicit `root:` `Root`'s `scope_id` does not match the
      #   wrapper id, or if `root:` is any other value.
      def resolve_root!
        case @root_option
        when true
          raise ArgumentError, "move_urls is required when root: true" if @move_urls.nil?

          OpPrimer::SortableLists::Root.new(scope_id: @wrapper_id, move_urls: @move_urls)
        when OpPrimer::SortableLists::Root
          assert_root_scope_matches_wrapper!(@root_option)
          @root_option
        when nil
          nil
        else
          raise ArgumentError, "expected true, OpPrimer::SortableLists::Root, or nil — got #{@root_option.class}"
        end
      end

      # @return [void]
      # @raise [ArgumentError] if `root`'s `scope_id` does not match the
      #   wrapper id — a mismatched scope would derive outlet selectors that
      #   search under the wrong element.
      def assert_root_scope_matches_wrapper!(root)
        return if root.scope_id == @wrapper_id

        raise ArgumentError,
              "root scope_id (#{root.scope_id.inspect}) must match the wrapper id (#{@wrapper_id.inspect})"
      end

      # Wires the wrapper as the page-level sortable-lists root.
      #
      # @return [void]
      def configure_root_wiring!
        return unless @root

        @system_arguments[:data] = @root.merge_into(@system_arguments[:data] || {})
      end

      # @param config [OpPrimer::SortableLists::List, Hash, nil]
      # @param klass [Class] `OpPrimer::SortableLists::List`.
      # @return [Object, nil] a `klass` instance, or `nil`.
      def coerce_sortable(config, klass)
        case config
        when nil, klass then config
        when Hash then klass.new(**config)
        else
          raise ArgumentError, "expected #{klass}, Hash, or nil — got #{config.class}"
        end
      end

      # @param config [OpPrimer::SortableLists::Item, Hash] row-level sortable
      #   wiring. A Hash without `type:` defaults it from `@sortable_list`'s
      #   accepted type.
      # @return [OpPrimer::SortableLists::Item]
      def coerce_row_sortable(config)
        raise ArgumentError, "with_item_row(sortable:) requires the component's sortable_list:" unless @sortable_list

        case config
        when OpPrimer::SortableLists::Item then config
        when Hash then OpPrimer::SortableLists::Item.new(type: @sortable_list.accepted_type, **config)
        else
          raise ArgumentError, "expected OpPrimer::SortableLists::Item, Hash, or nil — got #{config.class}"
        end
      end

      # @param caller_data [Hash, nil] hand-wired `data:` hash supplied by the caller.
      # @param generated_data [Hash] sortable-lists `data:` hash produced internally.
      # @return [void]
      # @raise [ArgumentError] if `caller_data` hand-wires a `sortable_lists__*`
      #   key that the generated wiring also sets.
      def assert_no_sortable_conflicts!(caller_data, generated_data)
        return if caller_data.blank?

        generated_keys = generated_data.keys.map(&:to_s).select { |key| key.start_with?("sortable_lists__") }
        caller_keys = caller_data.keys.map(&:to_s)
        conflicts = generated_keys & caller_keys
        return if conflicts.empty?

        raise ArgumentError, "sortable wiring conflicts with hand-wired data keys: #{conflicts.join(', ')}"
      end
    end
  end
end

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
    # A Primer BorderBox-backed list composition with optional header, items,
    # empty state, and footer.
    #
    # Use this component for compact lists that need consistent OpenProject
    # header actions, collapsible behavior, and row rendering.
    class BorderBoxListComponent < ApplicationComponent
      include OpPrimer::ComponentHelpers
      include OpPrimer::AttributesHelper
      include Primer::FetchOrFallbackHelper

      SCHEME_DEFAULT = :default
      SCHEME_OPTIONS = [SCHEME_DEFAULT, :transparent].freeze
      HEADER_PADDING_DEFAULT = :inherit
      HEADER_PADDING_OPTIONS = [HEADER_PADDING_DEFAULT, :condensed, :default, :spacious].freeze
      EMPTY_STATE_BEHAVIOR_DEFAULT = :static
      EMPTY_STATE_BEHAVIOR_OPTIONS = [EMPTY_STATE_BEHAVIOR_DEFAULT, :none, :dynamic].freeze

      attr_reader :container, :scheme, :header_padding, :empty_state_behavior, :collapsible, :current_user,
                  :header_id, :footer_id, :list_id

      alias_method :collapsible?, :collapsible

      # Optional header row.
      #
      # @!parse
      #   # Adds the optional header row.
      #   #
      #   # @param title [String] header title.
      #   # @param show_drag_handle [Boolean] whether the header renders a
      #   #   leading drag handle.
      #   # @param system_arguments [Hash] forwarded to {Header}. List wiring
      #   #   arguments are supplied internally.
      #   # @return [ViewComponent::Slot]
      #   def with_header(title: nil, show_drag_handle: false, **system_arguments, &block)
      #   end
      renders_one :header, ->(**system_arguments) {
        system_arguments = system_arguments.except(:id, :list_id)
        system_arguments[:id] = header_id
        system_arguments[:list_id] = list_id
        system_arguments[:interactive] = interactive?
        system_arguments[:collapsible] = collapsible?
        system_arguments[:sortable_handle] = @sortable_item.present? || @sortable_handle

        Header.new(**system_arguments)
      }

      # List row content.
      #
      # Use:
      #
      # - `item` for generic row content.
      # - `work_package_item` for rows backed by a work package card.
      #
      # @!parse
      #   # Adds a generic list row.
      #   #
      #   # @param sortable [OpPrimer::SortableLists::Item, Hash, nil] sortable
      #   #   wiring for this row. A Hash's `type:` defaults from the
      #   #   component's `sortable_list:` accepted type when omitted.
      #   #   Requires the component's `sortable_list:` to be set.
      #   # @param system_arguments [Hash] forwarded to Primer's BorderBox row.
      #   # @return [ViewComponent::Slot]
      #   def with_item(sortable: nil, **system_arguments, &block)
      #   end
      #
      #   # Adds a work-package list row.
      #   #
      #   # @param work_package [WorkPackage] work package rendered by the row.
      #   # @param project [Project] project context for the work package.
      #   # @param params [Hash] request params used by specialized item classes.
      #   # @param component_klass [Class] item component class to instantiate.
      #   #   Custom classes must accept `work_package:`, `project:`, `params:`,
      #   #   `container:`, `current_user:`, and any forwarded item arguments.
      #   # @param item_arguments [Hash] forwarded to the item component.
      #   # @return [ViewComponent::Slot]
      #   def with_work_package_item(
      #     work_package:,
      #     project: work_package.project,
      #     params: {},
      #     component_klass: WorkPackageItem,
      #     **item_arguments,
      #     &block
      #   )
      #   end
      renders_many :items, types: {
        item: {
          renders: ->(sortable: nil, **system_arguments) {
            if sortable
              raise ArgumentError, "with_item(sortable:) requires the component's sortable_list:" unless @sortable_list

              sortable = coerce_row_sortable(sortable)
              item_data = sortable.to_data
              assert_no_sortable_conflicts!(system_arguments[:data], item_data)
              system_arguments[:data] = merge_data(
                { data: system_arguments[:data] || {} },
                { data: item_data }
              )
            end

            Item.new(**system_arguments)
          },
          as: :item
        },
        work_package_item: {
          renders: ->(
            work_package:,
            project: work_package.project,
            params: {},
            component_klass: WorkPackageItem,
            **item_arguments
          ) {
            component_klass.new(
              work_package:,
              project:,
              params:,
              container:,
              current_user:,
              **item_arguments
            )
          },
          as: :work_package_item
        }
      }

      # Optional empty-state content rendered when no items are present.
      # When omitted, the component renders a generic default empty state.
      #
      # @!parse
      #   # Adds custom empty-state content.
      #   #
      #   # @param title [String] empty-state title.
      #   # @param description [String, nil] optional supporting text.
      #   # @param icon [Symbol, nil] optional Primer icon.
      #   # @param drop_target_label [String, nil] when given, renders a
      #   #   drop-zone overlay with this label. The overlay becomes visible
      #   #   while a sortable item hovers the surrounding
      #   #   `[data-drop-container="active"]` list. Defaults to the
      #   #   component's `sortable_list:` name when set and no label is given.
      #   # @param action_label [String, nil] optional call-to-action rendered
      #   #   as the blankslate's primary action.
      #   # @param action_icon [Symbol, nil] optional leading icon for the
      #   #   call-to-action.
      #   # @param action_arguments [Hash] forwarded to the primary-action
      #   #   button (e.g. `href:`, `scheme:`, `data:`).
      #   # @param system_arguments [Hash] forwarded to `Primer::Beta::Blankslate`.
      #   # @return [ViewComponent::Slot]
      #   def with_empty_state(title:, description: nil, icon: nil, drop_target_label: nil,
      #                        action_label: nil, action_icon: nil, action_arguments: {}, **system_arguments)
      #   end
      renders_one :empty_state, ->(title:, description: nil, icon: nil, drop_target_label: @sortable_list&.name,
                                   action_label: nil, action_icon: nil, action_arguments: {}, **system_arguments) {
        EmptyState.new(
          title:,
          description:,
          icon:,
          interactive: interactive?,
          drop_target_label:,
          action_label:,
          action_icon:,
          action_arguments:,
          **system_arguments
        )
      }

      # Optional footer row.
      #
      # @!parse
      #   # Adds an optional footer row.
      #   #
      #   # @param system_arguments [Hash] forwarded to Primer's BorderBox
      #   #   footer. The `id` is generated internally for collapsible header
      #   #   wiring.
      #   # @return [ViewComponent::Slot]
      #   def with_footer(**system_arguments, &block)
      #   end
      renders_one :footer, ->(**system_arguments) {
        system_arguments = system_arguments.except(:id)
        system_arguments[:id] = footer_id

        Footer.new(**system_arguments)
      }

      # @param container [String, Symbol, Class, Object] value passed to
      #   `dom_target` to derive DOM ids for the list and related controls.
      # @param scheme [Symbol] visual scheme. `:default` renders the standard
      #   BorderBox header. `:transparent` renders a transparent header with no
      #   separator line.
      # @param header_padding [Symbol] optional vertical padding override for
      #   the header. `:inherit` keeps Primer's padding from the underlying
      #   BorderBox. `:condensed`, `:default`, and `:spacious` override only
      #   the header's block padding.
      # @param empty_state_behavior [Symbol] policy for the empty state shown
      #   when the list has no items. `:static` (default) renders the generic
      #   empty state unless a custom one is declared via `with_empty_state`.
      #   `:none` suppresses the empty state entirely, including any declared
      #   slot. `:dynamic` reserves client-side lifecycle handling for
      #   sortable and filtered lists; no markup is added by this param yet.
      # @param interactive [Boolean] whether dynamic list updates should be
      #   announced politely to assistive technology. This affects the counter
      #   and empty-state content.
      # @param collapsible [Boolean] whether the header renders a collapsible
      #   toggle. Defaults to `false`.
      # @param sortable_list [OpPrimer::SortableLists::List, Hash, nil]
      #   sortable wiring for the box root, declaring it as a sortable-lists
      #   drop target for its rows. A Hash is coerced via
      #   `OpPrimer::SortableLists::List.new(**hash)`. Always mounts on the
      #   box root. Mutually exclusive with `sortable_item:` — see there for
      #   why.
      # @param sortable_item [OpPrimer::SortableLists::Item, Hash, nil]
      #   sortable wiring for the box root, declaring the whole list as a
      #   draggable item (e.g. a collapsible group nested inside another
      #   sortable list). A Hash is coerced via
      #   `OpPrimer::SortableLists::Item.new(**hash)`. Automatically gains a
      #   `"preview"` target and wires the header's drag handle when a header
      #   with `show_drag_handle: true` is present. Mutually exclusive with
      #   `sortable_list:`: `list.controller` and `item.controller` each
      #   unconditionally register their own Pragmatic `dropTargetForElements`
      #   on `this.element`, and Pragmatic's element adapter keys that
      #   registration by DOM node in a single shared registry, so mounting
      #   both controllers on one element would make whichever connects
      #   second silently replace the first's registration, breaking drops
      #   (see `frontend/.../pragmatic-drag-and-drop/.../make-drop-target.js`'s
      #   `registry.set`). Until the Stimulus controllers are taught to
      #   coexist on one element, the two stay mutually exclusive.
      # @param sortable_handle [Boolean] whether the box root gains a bare
      #   `"preview"` target and the header's drag handle gets wired, without
      #   a full `sortable_item:` (and its own item Stimulus controller). Use
      #   when the group's *rows* are the draggable unit but the group itself
      #   still needs a `preview` target for a header drag handle driven by
      #   some other reordering mechanism. Requires a header with
      #   `show_drag_handle: true` and is mutually exclusive with
      #   `sortable_item:` (which already implies it). Defaults to `false`.
      # @param current_user [User] user context passed to work-package items.
      # @param system_arguments [Hash] forwarded to `Primer::Beta::BorderBox`.
      #   Pass `id:` to set the box id; related ids are derived from it.
      def initialize( # rubocop:disable Metrics/AbcSize
        container:,
        scheme: SCHEME_DEFAULT,
        header_padding: HEADER_PADDING_DEFAULT,
        empty_state_behavior: EMPTY_STATE_BEHAVIOR_DEFAULT,
        interactive: false,
        collapsible: false,
        sortable_list: nil,
        sortable_item: nil,
        sortable_handle: false,
        current_user: User.current,
        **system_arguments
      )
        super()

        @container = container
        @scheme = ActiveSupport::StringInquirer.new(
          fetch_or_fallback(SCHEME_OPTIONS, scheme, SCHEME_DEFAULT).to_s
        )
        @header_padding = ActiveSupport::StringInquirer.new(
          fetch_or_fallback(HEADER_PADDING_OPTIONS, header_padding, HEADER_PADDING_DEFAULT).to_s
        )
        @empty_state_behavior = ActiveSupport::StringInquirer.new(
          fetch_or_fallback(EMPTY_STATE_BEHAVIOR_OPTIONS, empty_state_behavior, EMPTY_STATE_BEHAVIOR_DEFAULT).to_s
        )
        @interactive = interactive
        @collapsible = collapsible
        @sortable_list = coerce_sortable(sortable_list, OpPrimer::SortableLists::List)
        @sortable_item = coerce_sortable(sortable_item, OpPrimer::SortableLists::Item)
        @sortable_handle = sortable_handle
        @current_user = current_user
        @system_arguments = system_arguments.except(:list_id, :list_arguments)

        assert_no_combined_sortable_roles!

        @system_arguments[:id] ||= dom_target(container)
        @list_id = dom_target(@system_arguments[:id], :list)
        @system_arguments[:list_arguments] =
          if @empty_state_behavior.dynamic?
            { id: @list_id, data: { "border-box-list-target": "list" } }
          else
            { id: @list_id }
          end
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "op-border-box-list",
          "op-border-box-list_transparent" => @scheme.transparent?,
          "op-border-box-list_header-padding-condensed" => @header_padding.condensed?,
          "op-border-box-list_header-padding-default" => @header_padding.default?,
          "op-border-box-list_header-padding-spacious" => @header_padding.spacious?
        )

        # The list role lands on the box root (not the items `<ul>`): the CSS
        # drop indicators and the empty-state drop overlay both key off
        # `.op-border-box-list[data-drop-container]`, and `list.controller`
        # resolves its own rows container relative to its own element via
        # `:scope > ul`, so it needs to mount above that `<ul>`, not on it.
        # `sortable_list:` and `sortable_item:` can no longer be combined
        # (see `assert_no_combined_sortable_roles!`), so this is now
        # unconditional — no more falling back to the items `<ul>`.
        configure_sortable_list_wiring!
        configure_sortable_item_wiring!

        @header_id = dom_target(@system_arguments[:id], :header)
        @footer_id = dom_target(@system_arguments[:id], :footer)
      end

      def before_render
        content
        assert_sortable_handle_requires_drag_handle!
        configure_empty_state!
        configure_header!
      end

      def render?
        # rubocop:disable Style/InverseMethods -- `none?` is StringInquirer#none?, not Enumerable#none?
        header? || items.any? || (empty_state? && !empty_state_behavior.none?) || footer?
        # rubocop:enable Style/InverseMethods
      end

      private

      def interactive?
        @interactive == true
      end

      def configure_header!
        return unless header?

        header.resolve_count!(items.size)
        return unless collapsible? && footer?

        header.collapsible_id = [list_id, footer_id].compact.join(" ")
      end

      def configure_empty_state!
        return unless empty_state_behavior.static? || empty_state_behavior.dynamic?
        return if empty_state?
        # :dynamic lists always need prototype content for the parked template,
        # even when currently populated, so a client-side drain to zero rows has
        # a real blankslate to clone instead of a contentless placeholder.
        return if empty_state_behavior.static? && items.any?

        with_empty_state(
          title: I18n.t(:label_nothing_display),
          description: I18n.t(:no_results_title_text)
        )
      end

      # Wires the box root as a sortable-lists drop target for its rows.
      #
      # @return [void]
      def configure_sortable_list_wiring!
        return unless @sortable_list

        list_data = @sortable_list.to_data
        assert_no_sortable_conflicts!(@system_arguments[:data], list_data)
        @system_arguments[:data] = merge_data(
          { data: @system_arguments[:data] || {} },
          { data: list_data }
        )
      end

      # Wires the box root as a draggable item (`sortable_item:`), or — when
      # only `sortable_handle:` is set — as a bare `"preview"` target for a
      # header drag handle, without an item Stimulus controller.
      #
      # @return [void]
      def configure_sortable_item_wiring!
        return unless @sortable_item || @sortable_handle

        item_data =
          if @sortable_item
            @sortable_item.with_targets("preview").to_data
          else
            { sortable_lists__item_target: "preview" }
          end

        assert_no_sortable_conflicts!(@system_arguments[:data], item_data)
        @system_arguments[:data] = merge_data(
          { data: @system_arguments[:data] || {} },
          { data: item_data }
        )
      end

      # @param config [OpPrimer::SortableLists::List, OpPrimer::SortableLists::Item, Hash, nil]
      # @param klass [Class] `OpPrimer::SortableLists::List` or `OpPrimer::SortableLists::Item`.
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

      # @return [void]
      # @raise [ArgumentError] if `sortable_list:` and `sortable_item:` are
      #   both given, or if `sortable_handle:` is combined with
      #   `sortable_item:` (which already implies the handle wiring).
      def assert_no_combined_sortable_roles!
        if @sortable_list && @sortable_item
          raise ArgumentError,
                "BorderBoxListCollectionComponent cannot combine sortable_list: with sortable_item: — " \
                "list.controller and item.controller cannot yet share one element (see sortable_item: docs)"
        end

        return unless @sortable_handle && @sortable_item

        raise ArgumentError, "sortable_handle: is redundant with sortable_item:, which already wires the handle"
      end

      # @return [void]
      # @raise [ArgumentError] if `sortable_handle:` is set without a header
      #   showing `show_drag_handle: true`.
      def assert_sortable_handle_requires_drag_handle!
        return unless @sortable_handle
        return if header&.show_drag_handle?

        raise ArgumentError, "sortable_handle: requires a header with show_drag_handle: true"
      end
    end
  end
end

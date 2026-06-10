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
      include Primer::FetchOrFallbackHelper

      SCHEME_DEFAULT = :default
      SCHEME_OPTIONS = [SCHEME_DEFAULT, :transparent].freeze
      HEADER_PADDING_DEFAULT = :inherit
      HEADER_PADDING_OPTIONS = [HEADER_PADDING_DEFAULT, :condensed, :default, :spacious].freeze

      attr_reader :container, :scheme, :header_padding, :collapsible, :current_user, :header_id, :footer_id

      alias_method :collapsible?, :collapsible

      # Optional header row.
      #
      # @!parse
      #   # Adds the optional header row.
      #   #
      #   # @param system_arguments [Hash] forwarded to {Header}. List wiring
      #   #   arguments are supplied internally.
      #   # @return [ViewComponent::Slot]
      #   def with_header(**system_arguments, &block)
      #   end
      renders_one :header, ->(**system_arguments) {
        system_arguments = system_arguments.except(:id, :list_id)
        system_arguments[:id] = header_id
        system_arguments[:list_id] = list_id
        system_arguments[:interactive] = interactive?
        system_arguments[:collapsible] = collapsible?

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
      #   # @param system_arguments [Hash] forwarded to Primer's BorderBox row.
      #   # @return [ViewComponent::Slot]
      #   def with_item(**system_arguments, &block)
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
          renders: ->(**system_arguments) {
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
      #
      # @!parse
      #   # Adds empty-state content.
      #   #
      #   # Interactive lists announce this empty state only when the slot is
      #   # configured explicitly.
      #   #
      #   # @param title [String] empty-state title.
      #   # @param description [String, nil] optional supporting text.
      #   # @param icon [Symbol, nil] optional Primer icon.
      #   # @param system_arguments [Hash] forwarded to `Primer::Beta::Blankslate`.
      #   # @return [ViewComponent::Slot]
      #   def with_empty_state(title:, description: nil, icon: nil, **system_arguments)
      #   end
      renders_one :empty_state, ->(title:, description: nil, icon: nil, **system_arguments) {
        EmptyState.new(title:, description:, icon:, interactive: interactive?, **system_arguments)
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
      # @param interactive [Boolean] whether dynamic list updates should be
      #   announced politely to assistive technology. This affects the counter
      #   and an explicitly configured empty state; it does not create default
      #   empty-state content for manually composed lists.
      # @param collapsible [Boolean] whether the header renders a collapsible
      #   toggle. Defaults to `false`.
      # @param current_user [User] user context passed to work-package items.
      # @param system_arguments [Hash] forwarded to `Primer::Beta::BorderBox`.
      #   Pass `id:` to set the box id; related ids are derived from it.
      def initialize( # rubocop:disable Metrics/AbcSize
        container:,
        scheme: SCHEME_DEFAULT,
        header_padding: HEADER_PADDING_DEFAULT,
        interactive: false,
        collapsible: false,
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
        @interactive = interactive
        @collapsible = collapsible
        @current_user = current_user
        @system_arguments = system_arguments.except(:list_id)

        @system_arguments[:id] ||= dom_target(container)
        @system_arguments[:list_id] = dom_target(@system_arguments[:id], :list)
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "op-border-box-list",
          "op-border-box-list_transparent" => @scheme.transparent?,
          "op-border-box-list_header-padding-condensed" => @header_padding.condensed?,
          "op-border-box-list_header-padding-default" => @header_padding.default?,
          "op-border-box-list_header-padding-spacious" => @header_padding.spacious?
        )

        @header_id = dom_target(@system_arguments[:id], :header)
        @footer_id = dom_target(@system_arguments[:id], :footer)
      end

      def before_render
        content
        configure_header!
      end

      def render?
        header? || items.any? || empty_state? || footer?
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

      def list_id
        @system_arguments[:list_id]
      end
    end
  end
end

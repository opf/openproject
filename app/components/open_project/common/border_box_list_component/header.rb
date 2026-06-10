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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpenProject
  module Common
    class BorderBoxListComponent
      # Structured header for {BorderBoxListComponent}.
      #
      # This component is part of {BorderBoxListComponent} and should not be
      # used as a standalone component.
      #
      # The header renders through `Primer::Beta::BorderBox#with_header` and
      # wraps the supplied title, count, description, actions, and menu in an
      # `Primer::OpenProject::BorderBox::CollapsibleHeader`.
      class Header < ApplicationComponent
        include OpPrimer::ComponentHelpers
        include Primer::AttributesHelper
        include HasMenu

        DEFAULT_ACTION_SCHEME = :default

        DEFAULT_COUNT_ARGUMENTS = {
          scheme: :primary,
          round: true,
          limit: 1_000,
          hide_if_zero: true
        }.freeze

        # @!parse
        #   # Adds secondary content below the header title.
        #   #
        #   # The content is wrapped in `Primer::Beta::Text` with muted text
        #   # color by default. Pass Primer system arguments to adjust layout,
        #   # spacing, or color for more structured descriptions.
        #   #
        #   # @param system_arguments [Hash] forwarded to `Primer::Beta::Text`.
        #   # @return [ViewComponent::Slot]
        #   def with_description(**system_arguments, &block)
        #   end
        renders_one :description, ->(**system_arguments) do
          system_arguments[:color] ||= :muted

          Primer::Beta::Text.new(**system_arguments)
        end

        # @!parse
        #   # Adds a button to the header actions area.
        #   #
        #   # @param system_arguments [Hash] forwarded to `Primer::Beta::Button`.
        #   # @return [ViewComponent::Slot]
        #   def with_action_button(**system_arguments, &block)
        #   end
        renders_many :actions, types: {
          button: ->(scheme: DEFAULT_ACTION_SCHEME, **system_arguments) do
            Primer::Beta::Button.new(scheme:, **system_arguments)
          end
        }

        attr_reader :title,
                    :count,
                    :count_label,
                    :count_arguments,
                    :title_tag,
                    :title_arguments,
                    :list_id,
                    :interactive,
                    :collapsed,
                    :collapsible

        attr_writer :collapsible_id

        # @param title [String] header title.
        # @param count [Integer, Boolean, nil] count badge behavior. Pass
        #   `nil` or `false` to hide it, `true` to infer the rendered item
        #   count, or an integer to render an explicit value.
        # @param count_label [String, nil] accessible label for the counter
        #   badge. Defaults to `I18n.t(:label_x_items, count:)` when a count
        #   is rendered. Pass an explicit string to override.
        # @param count_arguments [Hash] forwarded to `Primer::Beta::Counter`.
        #   Values are merged over the default counter arguments.
        # @param title_tag [Symbol] tag used for the title heading.
        # @param title_arguments [Hash] forwarded to the title heading.
        # @param list_id [String, nil] id of the collapsible list body.
        # @param interactive [Boolean] whether counter updates should be
        #   announced politely to assistive technology.
        # @param collapsed [Boolean] whether the collapsible header starts closed.
        # @param collapsible [Boolean] whether the header renders a collapsible
        #   toggle. Defaults to `false`. Pass `true` to render a header
        #   with a toggle button.
        # @param system_arguments [Hash] forwarded to `Primer::Beta::BorderBox#with_header`.
        def initialize(
          title:,
          count: nil,
          count_label: nil,
          count_arguments: {},
          title_tag: :h4,
          title_arguments: {},
          list_id: nil,
          interactive: false,
          collapsed: false,
          collapsible: false,
          **system_arguments
        )
          super()

          @title = title
          @count = count
          @count_label = count_label
          @count_arguments = count_arguments
          @title_tag = title_tag
          @title_arguments = title_arguments.except(:tag)
          @list_id = list_id
          @interactive = interactive
          @collapsible_id = list_id
          @collapsed = collapsed
          @collapsible = collapsible
          @system_arguments = system_arguments
        end

        # @return [Boolean] whether a collapsible toggle should be rendered.
        def collapsible?
          collapsible
        end

        # Resolves inferred counts after the list slots have been captured.
        #
        # @param item_count [Integer] number of rendered item slots.
        # @return [void]
        def resolve_count!(item_count)
          @count = item_count if count == true
          @count_label ||= I18n.t(:label_x_items, count: @count) if render_count?
        end

        # @return [Hash] arguments forwarded to `Primer::Beta::BorderBox#with_header`.
        def row_args
          @system_arguments.deep_dup
        end

        # @return [Boolean] whether a counter should be rendered.
        def render_count?
          !count.nil? && count != false
        end

        # @return [Hash] merged arguments forwarded to `Primer::Beta::Counter`.
        def counter_arguments
          merged = DEFAULT_COUNT_ARGUMENTS.merge(count_arguments).merge(count:)
          default_aria = { label: count_label }
          default_aria[:live] = "polite" if interactive
          merged[:aria] = merge_aria(
            { aria: default_aria },
            merged
          )
          merged
        end

        # @return [String] classes forwarded to the non-collapsible title.
        def title_classes
          class_names("Box-title", title_arguments[:classes])
        end

        # @return [String, nil] ids controlled by the collapsible header.
        def collapsible_id
          @collapsible_id.presence
        end

        private

        def default_menu_id
          list_id ? "#{list_id}_menu" : super
        end
      end
    end
  end
end

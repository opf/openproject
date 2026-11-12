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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module OpPrimer
  # A low-level component for building semantic lists with unopinionated styling.
  #
  # This component is not designed to be used directly, but rather a primitive for
  # authors of other components.
  class ListComponent < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
    TAG_DEFAULT = :ul
    TAG_OPTIONS = [TAG_DEFAULT, :ol].freeze

    # @!parse
    #   # Adds an item to the list.
    #   #
    #   # @param system_arguments [Hash] These arguments are forwarded to <%= link_to_component(OpPrimer::ListComponent::Item) %>
    #   def with_item(**system_arguments, &block)
    #   end

    # @!parse
    #   # Adds a divider to the list. Dividers visually separate items.
    #   #
    #   # @param system_arguments [Hash] The arguments accepted by <%= link_to_component(OpPrimer:::ListComponent::Divider) %>.
    #   def with_divider(**system_arguments, &block)
    #   end
    renders_many :items, types: {
      item: {
        renders: ->(**item_arguments) { Item.new(**item_arguments) },
        as: :item
      },
      divider: {
        renders: -> { Divider.new },
        as: :divider
      }
    }

    # @param tag [Symbol] <%= one_of(OpPrimer::ListComponent::TAG_OPTIONS) %>
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(tag: TAG_DEFAULT, **system_arguments)
      super()

      @system_arguments = system_arguments
      @system_arguments[:tag] = fetch_or_fallback(TAG_OPTIONS, tag, TAG_DEFAULT)
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "list-style-none"
      )
    end

    def render?
      items.any? || content?
    end

    class Item < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
      def initialize(**system_arguments)
        super()

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :li
      end

      def call
        render(Primer::BaseComponent.new(**@system_arguments)) { content }
      end
    end

    class Divider < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
      def initialize(**system_arguments)
        super()

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :li
        @system_arguments[:role] = :presentation
        @system_arguments[:"aria-hidden"] = true
      end

      def call
        render(Primer::BaseComponent.new(**@system_arguments))
      end
    end
  end
end

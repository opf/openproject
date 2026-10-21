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
  # A low-level component for semantic definition lists with unopinionated styling.
  # Each item wraps one term and its descriptions in a div, which HTML permits
  # inside dl, so authors can lay a pair out without losing the dt/dd association.
  #
  # This component is not designed to be used directly, but rather a primitive for
  # authors of other components.
  class DefinitionListComponent < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
    class Term < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
      def initialize(**system_arguments)
        super()

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :dt
      end

      def call
        render(Primer::BaseComponent.new(**@system_arguments)) { content }
      end
    end

    class Description < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
      def initialize(**system_arguments)
        super()

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :dd
      end

      def call
        render(Primer::BaseComponent.new(**@system_arguments)) { content }
      end
    end

    class Item < Primer::Component # rubocop:disable OpenProject/AddPreviewForViewComponent
      # @!parse
      #   # Adds the term of this item.
      #   #
      #   # @param system_arguments [Hash] These arguments are forwarded to
      #   #   <%= link_to_component(OpPrimer::DefinitionListComponent::Term) %>
      #   def with_term(**system_arguments, &block)
      #   end

      # @!parse
      #   # Adds a description of this item. Called without a block, it renders an
      #   # empty dd for the caller to fill later.
      #   #
      #   # @param system_arguments [Hash] These arguments are forwarded to
      #   #   <%= link_to_component(OpPrimer::DefinitionListComponent::Description) %>
      #   def with_description(**system_arguments, &block)
      #   end
      renders_one :term, Term
      renders_many :descriptions, Description

      def initialize(**system_arguments)
        super()

        @system_arguments = deny_tag_argument(**system_arguments)
        @system_arguments[:tag] = :div
      end
    end

    # @!parse
    #   # Adds an item to the list: one term with its descriptions, wrapped in a div.
    #   #
    #   # @param system_arguments [Hash] These arguments are forwarded to
    #   #   <%= link_to_component(OpPrimer::DefinitionListComponent::Item) %>
    #   def with_item(**system_arguments, &block)
    #   end
    renders_many :items, Item

    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(**system_arguments)
      super()

      @system_arguments = deny_tag_argument(**system_arguments)
      @system_arguments[:tag] = :dl
    end

    def render?
      items.any? || content?
    end
  end
end

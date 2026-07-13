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

module Grids
  class WidgetBoxComponent < ApplicationComponent
    class Header < ApplicationComponent
      attr_reader :id, :title

      renders_one :action, types: {
        icon_button: lambda { |icon:, label:, **system_arguments|
          deny_tag_argument(**system_arguments)

          system_arguments[:icon] = icon
          system_arguments[:"aria-label"] ||= label

          Primer::Beta::IconButton.new(**system_arguments)
        },
        menu: {
          renders: lambda { |menu_arguments: {}, button_arguments: {}|
            MenuButton.new(menu_arguments: menu_arguments, button_arguments: button_arguments)
          }
        }
      }

      # @param attribute_label [Hash, nil] Optional args for AttributeLabelComponent (model:, attribute:, current_user:)
      # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
      def initialize(title:, attribute_label: nil, **system_arguments)
        super()
        @title = title
        @attribute_label_args = attribute_label
        @system_arguments = system_arguments
        @system_arguments[:tag] = :header
        @system_arguments[:id] ||= self.class.generate_id
        @system_arguments[:test_selector] = "op-widget-box--header"
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          "op-widget-box--header"
        )
        @id = @system_arguments[:id]
      end

      def render?
        title.present?
      end

      # Copied from Primer::Beta::ButtonGroup::MenuButton
      # Renders a button in a WidgetBoxComponent::Header that displays an ActionMenu when clicked.
      # This component should not be used outside of a `WidgetBoxComponent::Header` context.
      #
      # This component yields both the button and the list to the block when rendered.
      #
      # ```erb
      # <%= render(WidgetBoxComponent::Header.new) do |header| %>
      #   <% header.with_action_menu do |menu, button| %>
      #     <% menu.with_item(label: "Item 1") %>
      #     <% button.with_trailing_visual_icon(icon: "triangle-down") %>
      #   <% end %>
      # <% end %>
      # ```
      #
      class MenuButton < Primer::Component
        # @param menu_arguments [Hash] The arguments accepted by Primer::Alpha::ActionMenu.
        # @param button_arguments [Hash] The arguments accepted by Primer::Beta::Button or Primer::Beta::IconButton,
        # depending on the value of the `icon:` argument.
        def initialize(menu_arguments: {}, button_arguments: {})
          @menu = Primer::Alpha::ActionMenu.new(**menu_arguments)
          @button = @menu.with_show_button(**button_arguments)
          super()
        end

        def render_in(view_context, &)
          super do
            yield(@menu, @button)
          end
        end

        def before_render
          content
        end

        def call
          render(@menu)
        end
      end
    end
  end
end

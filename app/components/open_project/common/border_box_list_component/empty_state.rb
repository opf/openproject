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
      # Empty-state content rendered as a Primer Blankslate, wrapped in an
      # empty-state container that can host a drop-zone overlay.
      #
      # This component is part of {BorderBoxListComponent} and should not be
      # used as a standalone component.
      #
      class EmptyState < ApplicationComponent
        include Primer::AttributesHelper

        # @param title [String] empty-state heading.
        # @param description [String, nil] optional supporting text.
        # @param icon [Symbol, nil] optional Primer icon.
        # @param interactive [Boolean] whether empty-state updates should be
        #   announced politely to assistive technology.
        # @param drop_target_label [String, nil] when given, renders a drop-zone
        #   overlay with this label. The overlay becomes visible while a
        #   sortable item hovers the surrounding `[data-drop-container="active"]`
        #   list.
        # @param action_label [String, nil] optional call-to-action rendered as
        #   the blankslate's primary action.
        # @param action_icon [Symbol, nil] optional leading icon for the
        #   call-to-action.
        # @param action_arguments [Hash] forwarded to the primary-action button
        #   (e.g. `href:`, `scheme:`, `data:`).
        # @param system_arguments [Hash] forwarded to `Primer::Beta::Blankslate`.
        def initialize(
          title:,
          description: nil,
          icon: nil,
          interactive: false,
          drop_target_label: nil,
          action_label: nil,
          action_icon: nil,
          action_arguments: {},
          **system_arguments
        )
          super()

          @title = title
          @description = description
          @icon = icon
          @drop_target_label = drop_target_label
          @action_label = action_label
          @action_icon = action_icon
          @action_arguments = action_arguments.deep_dup

          @system_arguments = system_arguments
          return unless interactive

          @system_arguments[:role] ||= "status"
          @system_arguments[:aria] = merge_aria(
            { aria: { live: "polite" } },
            @system_arguments
          )
        end

        private

        attr_reader :drop_target_label

        def blankslate
          blankslate = Primer::Beta::Blankslate.new(**@system_arguments)
          blankslate.with_heading(tag: :h4).with_content(@title)
          blankslate.with_description_content(@description) if @description
          blankslate.with_visual_icon(icon: @icon) if @icon

          if @action_label.present?
            action = blankslate.with_primary_action(**@action_arguments)
            action.with_leading_visual_icon(icon: @action_icon) if @action_icon
            action.with_content(@action_label)
          end

          blankslate
        end
      end
    end
  end
end

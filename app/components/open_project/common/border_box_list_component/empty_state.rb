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
      # Empty-state content rendered as a Primer Blankslate.
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
        # @param system_arguments [Hash] forwarded to `Primer::Beta::Blankslate`.
        def initialize(title:, description: nil, icon: nil, interactive: false, **system_arguments)
          super()

          @title = title
          @description = description
          @icon = icon

          @system_arguments = system_arguments
          return unless interactive

          @system_arguments[:role] ||= "status"
          @system_arguments[:aria] = merge_aria(
            { aria: { live: "polite" } },
            @system_arguments
          )
        end

        def call
          blankslate = Primer::Beta::Blankslate.new(**@system_arguments)
          blankslate.with_heading(tag: :h4).with_content(@title)
          blankslate.with_description_content(@description) if @description
          blankslate.with_visual_icon(icon: @icon) if @icon

          render(blankslate)
        end
      end
    end
  end
end

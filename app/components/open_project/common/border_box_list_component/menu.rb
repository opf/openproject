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
      # Action menu wrapper for list headers and rows.
      #
      # The wrapper owns the default trigger decision while keeping the normal
      # Primer ActionMenu slot API available to callers.
      class Menu < ApplicationComponent
        include Primer::AttributesHelper

        DEFAULT_BUTTON_ARGUMENTS = {
          scheme: :invisible,
          icon: :"kebab-horizontal",
          tooltip_direction: :se
        }.freeze

        delegate :items,
                 :with_item,
                 :with_avatar_item,
                 :with_divider,
                 :with_group,
                 :with_sub_menu_item,
                 to: :@menu

        def initialize(button_arguments: {}, **system_arguments)
          super()

          @button_arguments = DEFAULT_BUTTON_ARGUMENTS.merge(button_arguments.deep_dup)
          @button_arguments[:aria] = merge_aria(
            { aria: { label: I18n.t(:label_actions) } },
            @button_arguments
          )
          @show_button_configured = false
          @menu = Primer::Alpha::ActionMenu.new(**system_arguments)
        end

        def with_show_button(**system_arguments, &)
          @show_button_configured = true
          @menu.with_show_button(**system_arguments, &)
        end

        def call
          render(@menu)
        end

        private

        def before_render
          content
          configure_default_show_button!
        end

        def configure_default_show_button!
          return if @show_button_configured

          @menu.with_show_button(**@button_arguments)
        end
      end
    end
  end
end

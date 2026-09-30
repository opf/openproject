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
#
module OpenProject
  module Common
    class MainMenuToggleComponent < ApplicationComponent
      include Primer::AttributesHelper

      def initialize(expanded:, **system_arguments)
        super()

        @system_arguments = system_arguments
        @system_arguments[:scheme] = :invisible
        @system_arguments[:icon] = expanded ? :"sidebar-expand" : :"sidebar-collapse"
        @system_arguments[:size] = expanded ? :medium : :small
        @system_arguments[:id]   = "menu-toggle--#{expanded ? 'collapse-button' : 'expand-button'}"
        @system_arguments[:data] = merge_data(
          @system_arguments,
          data: { action: "click->menus--main-toggle#toggleNavigation" }
        )
        @system_arguments[:aria] = merge_aria(
          @system_arguments,
          aria: {
            expanded:,
            label: expanded ? I18n.t("js.label_hide_project_menu") : I18n.t("js.label_expand_project_menu")
          }
        )
      end

      def call
        render(Primer::Beta::IconButton.new(**@system_arguments))
      end
    end
  end
end

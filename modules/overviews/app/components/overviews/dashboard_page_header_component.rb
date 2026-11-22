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

module Overviews
  class DashboardPageHeaderComponent < Primer::OpenProject::PageHeader
    class Tab < Primer::Alpha::Navigation::Tab
      def initialize(menu:, wrapper_arguments: {}, **)
        @menu = menu
        super(wrapper_arguments: wrapper_arguments.merge(classes: "op-dashboard-tab"), **)
      end

      def wrapper(&)
        super do
          safe_join([view_context.capture(&), render(@menu)])
        end
      end
    end

    class TabNav < Primer::Alpha::TabNav
      renders_many :dashboard_tabs, lambda { |selected: false, menu: nil, **system_arguments|
        system_arguments[:classes] = tab_nav_tab_classes(system_arguments[:classes])
        if menu
          Tab.new(list: true, selected:, menu:, **system_arguments)
        else
          Primer::Alpha::Navigation::Tab.new(list: true, selected:, **system_arguments)
        end
      }

      def tabs = dashboard_tabs
    end

    renders_one :dashboard_tab_nav, lambda { |**system_arguments, &block|
      @system_arguments[:classes] = class_names(@system_arguments[:classes], "PageHeader--withTabNav")
      system_arguments = deny_tag_argument(**system_arguments)
      system_arguments[:classes] = class_names(system_arguments[:classes], "PageHeader-tabNav")
      TabNav.new(tag: :div, **system_arguments, &block)
    }

    def tab_nav = dashboard_tab_nav
  end
end

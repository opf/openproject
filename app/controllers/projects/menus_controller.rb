# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++
module Projects
  class MenusController < ApplicationController
    # No authorize as every user (or logged in user)
    # is allowed to see the menu.

    def show
      @sidebar_menu_items = first_level_menu_items
      render layout: nil
    end

    private

    def first_level_menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil, children: static_filters)
      ]
    end

    def static_filters
      [
        menu_item(I18n.t(:label_all_projects),
                  []),
        menu_item(I18n.t(:label_my_projects),
                  [{ member_of: { operator: '=', values: ['t'] } }]),
        menu_item(I18n.t(:label_public_projects),
                  [{ public: { operator: '=', values: ['t'] } }]),
        menu_item(I18n.t(:label_archived_projects),
                  [{ active: { operator: '=', values: ['f'] } }])
      ]
    end

    def menu_item(title, filters)
      href = projects_path_with_filters(filters)

      OpenProject::Menu::MenuItem.new(title:,
                                      href:,
                                      selected: item_selected?(filters))
    end

    def projects_path_with_filters(filters)
      return projects_path if filters.empty?

      projects_path(filters: filters.to_json, hide_filters_section: true)
    end

    def item_selected?(filters)
      active_filters = JSON.parse(params[:filters] || '[]')

      filters == active_filters.map(&:deep_symbolize_keys)
    rescue JSON::ParserError
      false
    end
  end
end

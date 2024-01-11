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
        OpenProject::Menu::MenuGroup.new(header: nil,
                                         children: static_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:'projects.menu.my_private_lists'),
                                         children: my_filters)
      ]
    end

    def static_filters
      [
        filter_menu_item(I18n.t(:'projects.sidemenu.all'),
                         [],
                         selected: filters_in_props.nil? && query_in_props.nil?),
        filter_menu_item(I18n.t(:'projects.sidemenu.my'),
                         [{ member_of: { operator: '=', values: ['t'] } }]),
        filter_menu_item(I18n.t(:'projects.sidemenu.archived'),
                         [{ active: { operator: '=', values: ['f'] } }])
      ]
    end

    def my_filters
      Queries::Projects::ProjectQuery
        .where(user: current_user)
        .order(:name)
        .map do |query|
        query_menu_item(query)
      end
    end

    def filter_menu_item(title, filters, selected: filter_item_selected?(filters))
      OpenProject::Menu::MenuItem.new(title:,
                                      href: projects_path_with_filters(filters),
                                      selected:)
    end

    def query_menu_item(query)
      OpenProject::Menu::MenuItem.new(title: query.name,
                                      href: projects_path(query_id: query.id),
                                      selected: query_item_selected?(query))
    end

    def projects_path_with_filters(filters)
      return projects_path if filters.empty?

      projects_path(filters: filters.to_json, hide_filters_section: true)
    end

    def filter_item_selected?(filters)
      filters == filters_in_props && query_in_props.nil?
    end

    def query_item_selected?(query)
      query.id.to_s == query_in_props && filters_in_props.nil?
    end

    def query_in_props
      params[:query_id]
    end

    def filters_in_props
      @filters_in_props ||= begin
        # Will have to recheck params[:filters] again in case it is empty but that is cheap.
        JSON.parse(params[:filters]).map(&:deep_symbolize_keys) if params[:filters]
      rescue JSON::ParserError
        nil
      end
    end
  end
end

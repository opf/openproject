#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module Menus
  class Projects
    include Rails.application.routes.url_helpers

    attr_reader :controller_path, :params, :current_user

    def initialize(controller_path:, params:, current_user:)
      # rubocop:disable Rails/HelperInstanceVariable
      @controller_path = controller_path
      @params = params
      @current_user = current_user
      # rubocop:enable Rails/HelperInstanceVariable
    end

    def first_level_menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil,
                                         children: main_static_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:"projects.lists.my_private"),
                                         children: my_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:"activerecord.attributes.project.status_code"),
                                         children: status_static_filters)
      ]
    end

    private

    def main_static_filters
      static_filters [
        ::Queries::Projects::Factory::STATIC_ACTIVE,
        ::Queries::Projects::Factory::STATIC_MY,
        ::Queries::Projects::Factory::STATIC_FAVORED,
        ::Queries::Projects::Factory::STATIC_ARCHIVED
      ]
    end

    def status_static_filters
      static_filters [
        ::Queries::Projects::Factory::STATIC_ON_TRACK,
        ::Queries::Projects::Factory::STATIC_OFF_TRACK,
        ::Queries::Projects::Factory::STATIC_AT_RISK
      ]
    end

    def static_filters(ids)
      ids.map do |id|
        query_menu_item(::Queries::Projects::Factory.static_query(id), id:)
      end
    end

    def my_filters
      ::Queries::Projects::ProjectQuery
        .where(user: current_user)
        .order(:name)
        .map { |query| query_menu_item(query) }
    end

    def query_menu_item(query, id: nil)
      OpenProject::Menu::MenuItem.new(title: query.name,
                                      href: projects_path(query_id: id || query.id),
                                      selected: query_item_selected?(id || query.id))
    end

    def query_item_selected?(id)
      case controller_path
      when "projects"
        case params[:query_id]
        when nil
          id.to_s == Queries::Projects::Factory::DEFAULT_STATIC
        when /\A\d+\z/
          id.to_s == params[:query_id]
        else
          id.to_s == params[:query_id] unless modification_params?
        end
      when "projects/queries"
        id.to_s == params[:id]
      end
    end

    def modification_params?
      params.values_at(:filters, :columns, :sortBy).any?
    end
  end
end

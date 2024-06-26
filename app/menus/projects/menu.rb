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

module Projects
  class Menu < Submenu
    include Rails.application.routes.url_helpers

    attr_reader :controller_path, :params, :current_user

    def initialize(params:, controller_path:, current_user:)
      @params = params
      @controller_path = controller_path
      @current_user = current_user

      super(view_type:, project:, params:)
    end

    def menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil, children: main_static_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:"projects.lists.public"), children: public_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:"projects.lists.my_private"), children: my_filters),
        OpenProject::Menu::MenuGroup.new(header: I18n.t(:"activerecord.attributes.project.status_code"),
                                         children: status_static_filters)
      ]
    end

    def selected?(query_params)
      case controller_path
      when "projects"
        case params[:query_id]
        when nil
          query_params[:query_id].to_s == Queries::Projects::Factory::DEFAULT_STATIC
        when /\A\d+\z/
          query_params[:query_id].to_s == params[:query_id]
        else
          query_params[:query_id].to_s == params[:query_id] unless modification_params?
        end
      when "projects/queries"
        query_params[:query_id].to_s == params[:id]
      end
    end

    def query_path(query_params)
      projects_path(query_params)
    end

    private

    def main_static_filters
      static_filters [
        ::Queries::Projects::Factory::STATIC_ACTIVE,
        ::Queries::Projects::Factory::STATIC_MY,
        ::Queries::Projects::Factory::STATIC_FAVORED,
        current_user.admin? ? ::Queries::Projects::Factory::STATIC_ARCHIVED : nil
      ].compact
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
        menu_item({ query_id: id }, ::Queries::Projects::Factory.static_query(id).name)
      end
    end

    def public_filters
      ::ProjectQuery
        .public_lists
        .order(:name)
        .map { |query| menu_item({ query_id: query.id }, query.name) }
    end

    def my_filters
      ::ProjectQuery
        .private_lists(user: current_user)
        .order(:name)
        .map { |query| menu_item({ query_id: query.id }, query.name) }
    end

    def modification_params?
      params.values_at(:filters, :columns, :sortBy).any?
    end
  end
end

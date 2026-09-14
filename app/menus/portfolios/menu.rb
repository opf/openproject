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

module Portfolios
  class Menu < Submenu
    include Rails.application.routes.url_helpers

    attr_reader :controller_path, :params, :current_user

    def initialize(params:, controller_path:, current_user:)
      @params = params
      @controller_path = controller_path
      @current_user = current_user

      super(view_type:, params:, project: nil)
    end

    def menu_items
      [
        OpenProject::Menu::MenuGroup.new(header: nil, children: main_static_filters)
      ]
    end

    def selected?(query_params)
      query_params[:query_id].to_s == selected_query_id
    end

    def query_path(query_params)
      portfolios_path(query_params)
    end

    private

    def selected_query_id
      case controller_path
      when "portfolios"
        if /\A\d+\z/.match?(params[:query_id])
          params[:query_id]
        elsif !modification_params?
          params[:query_id] || ProjectQueries::Static::ACTIVE_PORTFOLIOS
        end
      when "portfolios/queries"
        params[:id]
      end
    end

    def main_static_filters
      main_filters = [
        ProjectQueries::Static::ACTIVE_PORTFOLIOS,
        current_user.logged? ? ProjectQueries::Static::MY_PORTFOLIOS : nil,
        current_user.logged? ? ProjectQueries::Static::FAVORITED_PORTFOLIOS : nil,
        current_user.admin? ? ProjectQueries::Static::ARCHIVED_PORTFOLIOS : nil
      ]

      static_filters(main_filters.compact)
    end

    def static_filters(ids)
      ids.map do |id|
        menu_item(title: ::ProjectQueries::Static.query(id).name, query_params: { query_id: id })
      end
    end

    def modification_params?
      params.values_at(:filters, :sortBy).any?
    end
  end
end

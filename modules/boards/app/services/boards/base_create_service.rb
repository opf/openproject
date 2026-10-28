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

module Boards
  class BaseCreateService < ::Grids::CreateService
    protected

    def instance(attributes)
      Boards::Grid.new(
        name: attributes[:name],
        project: attributes[:project],
        row_count: row_count_for_board,
        column_count: column_count_for_board
      )
    end

    def before_perform(_service_result)
      return super if no_widgets_initially?

      create_query_result = create_query(params)

      return create_query_result if create_query_result.failure?

      params[:query_id] = create_query_result.result.id
      super(create_query_result)
    end

    def set_attributes_params(params)
      {}.tap do |grid_params|
        grid_params[:options] = options_for_grid(params)
        grid_params[:widgets] = options_for_widgets(params)
      end
    end

    def attributes_service_class
      BaseSetAttributesService
    end

    private

    def no_widgets_initially?
      false
    end

    def create_query(params)
      Queries::CreateService.new(user: User.current)
                            .call(create_query_params(params))
    end

    def create_query_params(params)
      default_create_query_params(params).merge(
        name: query_name,
        filters: query_filters
      )
    end

    def default_create_query_params(params)
      {
        project: params[:project],
        public: true,
        sort_criteria: query_sort_criteria
      }
    end

    def query_name
      raise "Define the query name"
    end

    def query_filters
      raise "Define the query filters"
    end

    def query_sort_criteria
      [[:manual_sorting, "asc"], [:id, "asc"]]
    end

    def options_for_grid(params)
      {}.tap do |options|
        if params[:attribute] == "basic"
          options[:type] = "free"
        else
          options[:type] = "action"
          options[:attribute] = params[:attribute]
        end
      end
    end

    def options_for_widgets(_params)
      return [] if no_widgets_initially?

      raise "Define the options for the grid widgets"
    end

    def row_count_for_board
      1
    end

    def column_count_for_board
      4
    end
  end
end

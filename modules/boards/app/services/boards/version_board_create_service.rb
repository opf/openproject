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
  class VersionBoardCreateService < BaseCreateService
    protected

    def before_perform(_service_result)
      create_queries_results = create_queries(params)

      return create_queries_results.find(&:failure?) if create_queries_results.any?(&:failure?)

      set_attributes(params.merge(query_ids: create_queries_results.map(&:result).map(&:id)))
    end

    private

    def column_count_for_board
      [super, versions(params).count].max
    end

    def create_queries(params)
      versions(params).map do |version|
        Queries::CreateService.new(user: User.current)
                              .call(create_query_params(params, version))
      end
    end

    def versions(params)
      @versions ||= Version.includes(:project)
                           .where(projects: { id: params[:project].id })
                           .with_status_open
    end

    def create_query_params(params, version)
      default_create_query_params(params).merge(
        name: query_name(version),
        filters: query_filters(version)
      )
    end

    def query_name(version)
      version.name
    end

    def query_filters(version)
      [{ version_id: { operator: "=", values: [version.id.to_s] } }]
    end

    def options_for_widgets(params)
      query_ids_with_versions = params[:query_ids].zip(versions(params))
      query_ids_with_versions.map.with_index do |(query_id, version), index|
        Grids::Widget.new(
          start_row: 1,
          start_column: 1 + index,
          end_row: 2,
          end_column: 2 + index,
          identifier: "work_package_query",
          options: {
            "queryId" => query_id,
            "filters" => query_filters(version)
          }
        )
      end
    end
  end
end

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

module API
  module V3
    class WorkPackageCollectionFromQueryService
      include Utilities::PathHelper
      include ::API::Utilities::UrlPropsParsingHelper

      def initialize(query, user, scope: nil)
        self.query = query
        self.current_user = user
        self.scope = scope
      end

      def call(params = {}, valid_subset: false)
        update = UpdateQueryFromV3ParamsService
                 .new(query, current_user)
                 .call(params, valid_subset:)

        if update.success?
          representer = results_to_representer(params)

          ServiceResult.success(result: representer)
        else
          update
        end
      end

      private

      def results_to_representer(params)
        results_scope = query.results.work_packages

        if scope
          results_scope = results_scope.where(id: scope.select(:id))
        end

        collection_representer(results_scope,
                               params:,
                               project: query.project,
                               groups: generate_groups,
                               sums: generate_total_sums)
      end

      attr_accessor :query,
                    :current_user,
                    :scope

      def representer
        ::API::V3::WorkPackages::WorkPackageCollectionRepresenter
      end

      def calculate_resulting_params(provided_params)
        calculate_default_params
          .merge(provided_params.slice('offset', 'pageSize').symbolize_keys)
          .tap do |params|
          if query.manually_sorted?
            params[:query_id] = query.id
            params[:offset] = 1
            # Force the setting value in all cases except when 0 is requested explicitly. Fetching with pageSize = 0
            # is done for performance reasons to simply get the query without the results.
            params[:pageSize] = pageSizeParam(params) == 0 ? pageSizeParam(params) : Setting.forced_single_page_size
          else
            params[:offset] = to_i_or_nil(params[:offset])
            params[:pageSize] = pageSizeParam(params)
          end

          params[:select] = nested_from_csv(provided_params['select']) if provided_params['select']
        end
      end

      def calculate_default_params
        ::API::V3::Queries::QueryParamsRepresenter
          .new(query)
          .to_h
      end

      def generate_groups
        return unless query.grouped?

        results = query.results
        sums = generate_group_sums

        results.work_package_count_by_group.map do |group, count|
          ::API::V3::WorkPackages::WorkPackageAggregationGroup.new(
            group, count, query:, sums: sums[group], current_user:
          )
        end
      end

      def generate_total_sums
        return unless query.display_sums?

        format_query_sums query.results.all_total_sums
      end

      def generate_group_sums
        return {} unless query.display_sums?

        query.results.all_group_sums.transform_values do |v|
          format_query_sums(v)
        end
      end

      def format_query_sums(sums)
        API::ParserStruct.new(format_column_keys(sums).merge(available_custom_fields: WorkPackageCustomField.summable.to_a))
      end

      def format_column_keys(hash_by_column)
        hash_by_column.map do |column, value|
          match = /cf_(\d+)/.match(column.name.to_s)

          column_name = if match
                          "custom_field_#{match[1]}"
                        else
                          column.name.to_s
                        end

          [column_name, value]
        end.to_h
      end

      def collection_representer(work_packages, params:, project:, groups:, sums:)
        resulting_params = calculate_resulting_params(params)

        if resulting_params[:select]
          ::API::V3::Utilities::SqlRepresenterWalker
            .new(work_packages,
                 current_user:,
                 self_path: self_link(project),
                 url_query: resulting_params)
            .walk(::API::V3::WorkPackages::WorkPackageSqlCollectionRepresenter)
        else
          ::API::V3::WorkPackages::WorkPackageCollectionRepresenter.new(
            work_packages,
            self_link: self_link(project),
            project:,
            query_params: resulting_params,
            page: resulting_params[:offset],
            per_page: resulting_params[:pageSize],
            groups:,
            total_sums: sums,
            embed_schemas: true,
            current_user:,
            timestamps: query.timestamps,
            query:
          )
        end
      end

      def to_i_or_nil(value)
        value ? value.to_i : nil
      end

      def pageSizeParam(params)
        to_i_or_nil(params[:pageSize])
      end

      def self_link(project)
        if project
          api_v3_paths.work_packages_by_project(project.id)
        else
          api_v3_paths.work_packages
        end
      end

      def convert_to_v3(attribute)
        ::API::Utilities::PropertyNameConverter.from_ar_name(attribute).to_sym
      end
    end
  end
end

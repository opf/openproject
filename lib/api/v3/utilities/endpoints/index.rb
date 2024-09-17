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

module API
  module V3
    module Utilities
      module Endpoints
        class Index < API::Utilities::Endpoints::Index
          def initialize(model:,
                         api_name: model.name.demodulize,
                         scope: nil,
                         render_representer: nil,
                         self_path: api_name.underscore.pluralize)
            super(model:, api_name:, scope:, render_representer:)

            self.self_path = self_path
          end

          def mount
            index = self

            -> do
              query = index.parse(self)

              index.render(self, query)
            end
          end

          def parse(request)
            ParamsToQueryService
              .new(model, request.current_user)
              .call(request.params)
          end

          def render(request, query)
            if query.valid?
              render_success(query,
                             request.params,
                             calculated_self_path(request),
                             scope ? request.instance_exec(&scope) : model)
            else
              raise_query_errors(query)
            end
          end

          attr_accessor :model,
                        :api_name,
                        :scope,
                        :render_representer,
                        :self_path

          private

          def render_success(query, params, self_path, base_scope)
            results = apply_scope_constraint(base_scope, query.results)

            if paginated_representer?
              render_paginated_success(results, query, params, self_path)
            else
              render_unpaginated_success(results, query, self_path)
            end
          end

          def render_paginated_success(results, query, params, self_path)
            resulting_params = calculate_resulting_params(query, params)

            render_representer
              .create(results,
                      self_link: self_path,
                      query_params: resulting_params,
                      page: resulting_params[:offset],
                      per_page: resulting_params[:pageSize],
                      groups: calculate_groups(query),
                      current_user: User.current)
          end

          def render_unpaginated_success(results, query, self_path)
            unpaginated_params = calculate_default_params(query).except(:offset, :pageSize)

            render_representer
              .new(results,
                   self_link: self_path,
                   query: unpaginated_params,
                   current_user: User.current)
          end

          def calculate_resulting_params(query, provided_params)
            calculate_default_params(query).merge(provided_params.slice("offset", "pageSize").symbolize_keys).tap do |params|
              params[:offset] = to_i_or_nil(params[:offset])
              params[:pageSize] = resolve_page_size(params[:pageSize])
            end
          end

          def calculate_groups(query)
            return unless query.respond_to?(:group_by) && query.group_by

            query.group_values.map do |group, count|
              ::API::Decorators::AggregationGroup.new(group, count, query:, current_user: User.current)
            end
          end

          def calculate_default_params(query)
            ::API::Decorators::QueryParamsRepresenter
              .new(query)
              .to_h
          end

          def paginated_representer?
            render_representer.ancestors.include?(::API::Decorators::OffsetPaginatedCollection)
          end

          def calculated_self_path(request)
            if self_path.respond_to?(:call)
              request.instance_exec(&self_path)
            else
              request.api_v3_paths.send(self_path)
            end
          end

          def deduce_render_representer
            "::API::V3::#{deduce_api_namespace}::#{api_name}CollectionRepresenter".constantize
          end

          def deduce_api_namespace
            api_name.pluralize
          end

          def model_class(scope)
            if scope.is_a? Class
              scope
            else
              scope.model
            end
          end

          def apply_scope_constraint(constraint, result_scope)
            if constraint.is_a?(Class)
              result_scope
            else
              result_scope
                .includes(constraint.includes_values)
                .merge constraint
            end
          end
        end
      end
    end
  end
end

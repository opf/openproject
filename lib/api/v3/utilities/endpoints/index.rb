#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Utilities
      module Endpoints
        class Index < API::Utilities::Endpoints::Index
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
                             request.api_v3_paths.send(self_path),
                             scope ? request.instance_exec(&scope) : model)
            else
              render_error(query)
            end
          end

          def self_path
            api_name.underscore.pluralize
          end

          attr_accessor :model,
                        :api_name,
                        :scope,
                        :render_representer

          private

          def render_success(query, params, self_path, base_scope)
            results = merge_scopes(base_scope, query.results)

            if paginated_representer?
              render_paginated_success(results, query, params, self_path)
            else
              render_unpaginated_success(results, self_path)
            end
          end

          def render_paginated_success(results, query, params, self_path)
            resulting_params = calculate_resulting_params(query, params)

            render_representer
              .new(results,
                   self_link: self_path,
                   query: resulting_params,
                   page: resulting_params[:offset],
                   per_page: resulting_params[:pageSize],
                   current_user: User.current)
          end

          def render_unpaginated_success(results, self_path)
            render_representer
              .new(results,
                   self_link: self_path,
                   current_user: User.current)
          end

          def calculate_resulting_params(query, provided_params)
            calculate_default_params(query).merge(provided_params.slice('offset', 'pageSize').symbolize_keys).tap do |params|
              params[:offset] = to_i_or_nil(params[:offset])
              params[:pageSize] = to_i_or_nil(params[:pageSize])
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

          def render_error(query)
            raise ::API::Errors::InvalidQuery.new(query.errors.full_messages)
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

          def merge_scopes(scope_a, scope_b)
            if scope_a.is_a? Class
              scope_b
            else
              scope_a.merge(scope_b)
            end
          end
        end
      end
    end
  end
end

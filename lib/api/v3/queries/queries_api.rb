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

require "securerandom"
require "api/v3/queries/query_representer"

module API
  module V3
    module Queries
      class QueriesAPI < ::API::OpenProjectAPI
        resources :queries do
          mount API::V3::Queries::Columns::QueryColumnsAPI
          mount API::V3::Queries::GroupBys::QueryGroupBysAPI
          mount API::V3::Queries::SortBys::QuerySortBysAPI
          mount API::V3::Queries::Filters::QueryFiltersAPI
          mount API::V3::Queries::Operators::QueryOperatorsAPI
          mount API::V3::Queries::Schemas::QuerySchemaAPI
          mount API::V3::Queries::Schemas::QueryFilterInstanceSchemaAPI
          mount API::V3::Queries::CreateFormAPI

          helpers ::API::V3::Queries::Helpers::QueryRepresenterResponse
          helpers ::API::V3::Queries::QueryHelper

          helpers do
            def authorize_by_policy(action, &)
              authorize_by_with_raise(-> { allowed_to?(action) }, &)
            end

            def allowed_to?(action)
              QueryPolicy.new(current_user).allowed?(@query, action)
            end
          end

          get do
            authorize_in_any_work_package(:view_work_packages) do
              authorize_in_any_project(:manage_public_queries)
            end

            queries_scope = Query.all.includes(QueryRepresenter.to_eager_load)

            ::API::V3::Utilities::ParamsToQuery.collection_response(queries_scope,
                                                                    current_user,
                                                                    params)
          end

          namespace "available_projects" do
            after_validation do
              authorize_in_any_work_package(:view_work_packages)
            end

            get do
              available_projects = Project.with_visible_work_packages
              self_link = api_v3_paths.query_available_projects

              ::API::V3::Projects::ProjectCollectionRepresenter.new(available_projects,
                                                                    self_link:,
                                                                    current_user:)
            end
          end

          namespace "default" do
            params do
              optional :valid_subset, type: Boolean
            end

            get do
              @query = Query.new_default(user: current_user)

              authorize_in_any_work_package(:view_work_packages)

              query_representer_response(@query, params, params.delete(:valid_subset))
            end
          end

          post &::API::V3::Utilities::Endpoints::Create
            .new(model: Query)
            .mount

          route_param :id, type: Integer, desc: "Query ID" do
            after_validation do
              @query = Query.find(params[:id])

              authorize_by_policy(:show) do
                raise API::Errors::NotFound
              end
            end

            mount API::V3::Queries::UpdateFormAPI

            patch &::API::V3::Utilities::Endpoints::Update
                     .new(model: Query)
                     .mount

            params do
              optional :valid_subset, type: Boolean
            end

            get do
              # We try to ignore invalid aspects of the query as the user
              # might not even be able to fix them (public  query)
              # and because they might only be invalid in his context
              # but not for somebody having more permissions, e.g. subproject
              # filter for admin vs for anonymous.
              # Permissions are enforced nevertheless.
              @query.valid_subset!

              # We do not ignore invalid params provided by the client
              # unless explicitly required by valid_subset
              query_representer_response(@query, params, params.delete(:valid_subset))
            end

            delete do
              authorize_by_policy(:destroy)

              @query.destroy

              status 204
            end

            namespace :star do
              patch &::API::V3::Utilities::Endpoints::Update
                       .new(model: Query,
                            params_modifier: ->(_params) {
                              { starred: true }
                            })
                       .mount
            end

            namespace :unstar do
              patch &::API::V3::Utilities::Endpoints::Update
                       .new(model: Query,
                            params_modifier: ->(_params) {
                              { starred: false }
                            })
                       .mount
            end

            mount API::V3::Queries::ICalUrl::QueryIcalUrlAPI

            mount API::V3::Queries::Order::QueryOrderAPI
          end
        end
      end
    end
  end
end

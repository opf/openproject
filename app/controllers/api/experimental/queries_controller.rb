#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api::Experimental
  class QueriesController < ApplicationController
    include ApiController
    include Api::Experimental::Concerns::GrapeRouting
    include Api::Experimental::Concerns::ColumnData
    include Api::Experimental::Concerns::QueryLoading
    include Api::Experimental::Concerns::V3Naming

    include QueriesHelper
    include ExtendedHTTP

    before_action :find_optional_project
    before_action :v3_params_as_internal, only: [:create, :update]
    before_action :setup_query_for_create, only: [:create]
    before_action :setup_existing_query, only: [:update, :destroy]
    before_action :authorize_on_query, only: [:create, :destroy]
    before_action :authorize_update_on_query, only: [:update]
    before_action :setup_query, only: [:available_columns, :custom_field_filters]

    def available_columns
      @available_columns = get_columns_for_json(@query.available_columns)

      respond_to do |format|
        format.api
      end
    end

    def custom_field_filters
      @custom_field_filters = fetch_custom_field_filters(@project)

      respond_to do |format|
        format.api
      end
    end

    def grouped
      @user_queries = visible_queries.reject(&:is_public?).map { |query| [query.name, query.id] }
      @queries = visible_queries.select(&:is_public?).map { |query| [query.name, query.id] }

      respond_to do |format|
        format.api
      end
    end

    def create
      if @query.save
        setup_query_links
        respond_to do |format|
          format.api
        end
      else
        render json: @query.errors.to_json, status: 422
      end
    end

    def update
      if @query.save
        setup_query_links
        respond_to do |format|
          format.api
        end
      else
        render json: @query.errors.to_json, status: 422
      end
    end

    def destroy
      @query.destroy
      respond_to do |format|
        format.api
      end
    end

    private

    def setup_query
      @query ||= init_query
    rescue ActiveRecord::RecordNotFound
      render_404
    end

    def setup_query_links
      @query_links = allowed_links_on_query(@query, current_user)
    end

    def setup_query_for_create
      @query = Query.new params[:query] ? permitted_params.query : nil
      @query.project = @project unless params[:query_is_for_all]
      prepare_query
      @query.user = User.current
    end

    def setup_existing_query
      @query = Query.find(params[:id])
      prepare_query
    end

    def authorize_on_query
      deny_access unless QueryPolicy.new(current_user).allowed?(@query, params[:action].to_sym)
    end

    def authorize_update_on_query
      original_query = Query.find(params[:id])
      actions = [:update]
      changed = @query.changed

      # On update we must distinguish between a usual request updating the query
      # and a request that (only) (de-)publicizes the query
      if changed.include? 'is_public'
        # The permission to change the public state is handled separately
        changed.delete('is_public')
        # ActiveRecord::Dirty will (nearly) always return 'filters' as changed,
        # because it compares filters via object identity. Thus, we need to
        # apply our own filter comparison to detect changed filters correctly.
        changed.delete('filters') if @query.filters == original_query.filters

        # Check user's publication permissions
        actions << (@query.is_public ? :publicize : :depublicize)
        # We don't need to check the update permission if the query is not
        # changed by the request. Otherwise the user would need to have the
        # update permission to change the publication state of a query.
        actions.delete(:update) if changed.empty?
      end

      policy = QueryPolicy.new(current_user)

      allowed = actions
                .map { |action| policy.allowed?(original_query, action.to_sym) }
                .reduce(:&)

      deny_access unless allowed
    end

    def fetch_custom_field_filters(project)
      filters = Queries::WorkPackages::Filter::CustomFieldFilter.all_for(project)

      filters.each_with_object({}) do |filter, hash|
        new_key = API::Utilities::PropertyNameConverter.from_ar_name(filter.name)
        hash[new_key] = { type: filter.type,
                          values: filter.allowed_values,
                          order: filter.order,
                          name: filter.human_name }
      end
    end
  end
end

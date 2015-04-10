#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module Api::Experimental
  class QueriesController < ApplicationController
    unloadable

    include ApiController
    include Api::Experimental::Concerns::GrapeRouting
    include Api::Experimental::Concerns::ColumnData
    include Api::Experimental::Concerns::QueryLoading

    include QueriesHelper
    include ExtendedHTTP

    before_filter :find_optional_project
    before_filter :setup_query_for_create, only: [:create]
    before_filter :setup_existing_query, only: [:update, :destroy]
    before_filter :authorize_on_query, only: [:create, :destroy]
    before_filter :authorize_update_on_query, only: [:update]
    before_filter :setup_query, only: [:available_columns, :custom_field_filters]

    def available_columns
      @available_columns = get_columns_for_json(@query.available_columns)

      respond_to do |format|
        format.api
      end
    end

    def custom_field_filters
      custom_fields = if @project
                        @project.all_work_package_custom_fields
                      else
                        WorkPackageCustomField.for_all
                      end
      @custom_field_filters = @query.get_custom_field_options(custom_fields)

      respond_to do |format|
        format.api
      end
    end

    def grouped
      @user_queries = visible_queries.select { |query| !query.is_public? }.map { |query| [query.name, query.id] }
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

      allowed = actions.map(&:to_sym)
                .map { |action| QueryPolicy.new(current_user).allowed?(original_query, action) }
                .reduce(:&)

      deny_access unless allowed
    end

    def visible_queries
      unless @visible_queries
        # User can see public queries and his own queries
        visible = ARCondition.new(['is_public = ? OR user_id = ?', true, (User.current.logged? ? User.current.id : 0)])
        # Project specific queries and global queries
        visible << (@project.nil? ? ['project_id IS NULL'] : ['project_id IS NULL OR project_id = ?', @project.id])
        @visible_queries = Query.find(:all,
                                      select: 'id, name, is_public',
                                      order: 'name ASC',
                                      conditions: visible.conditions)
      end
      @visible_queries
    end
  end
end

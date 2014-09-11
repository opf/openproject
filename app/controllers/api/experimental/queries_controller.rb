#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
      @user_queries = visible_queries.select{|query| !query.is_public?}.map{|query| [query.name, query.id]}
      @queries = visible_queries.select(&:is_public?).map{|query| [query.name, query.id]}

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

    def setup_query_links
      user = User.current
      @query_links = {}
      @query_links[:create] = api_experimental_queries_path if user.allowed_to?(:save_queries, @project, :global => @project.nil?)

      if !@query.new_record?
        @query_links[:update]      = api_experimental_query_path(@query) if user.allowed_to?(:save_queries, @project, :global => @project.nil?)
        @query_links[:delete]      = api_experimental_query_path(@query) if user.allowed_to?(:save_queries, @project, :global => @project.nil?)
        @query_links[:publicize]   = api_experimental_query_path(@query) if user.allowed_to?(:manage_public_queries, @project, :global => @project.nil?)
        @query_links[:depublicize] = api_experimental_query_path(@query) if user.allowed_to?(:manage_public_queries, @project, :global => @project.nil?)

        if ((@query.user_id == user.id && user.allowed_to?(:save_queries, @project, :global => @project.nil?)) ||
            user.allowed_to?(:manage_public_queries, @project, :global => @project.nil?))

          @query_links[:star]        = query_route_from_grape("star", @query)
          @query_links[:unstar]      = query_route_from_grape("unstar", @query)
        end
      end
    end

    def setup_query
      @query ||= init_query
    rescue ActiveRecord::RecordNotFound
      render_404
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

    def visible_queries
      unless @visible_queries
        # User can see public queries and his own queries
        visible = ARCondition.new(["is_public = ? OR user_id = ?", true, (User.current.logged? ? User.current.id : 0)])
        # Project specific queries and global queries
        visible << (@project.nil? ? ["project_id IS NULL"] : ["project_id IS NULL OR project_id = ?", @project.id])
        @visible_queries = Query.find(:all,
                                      :select => 'id, name, is_public',
                                      :order => "name ASC",
                                      :conditions => visible.conditions)
      end
      @visible_queries
    end
  end
end

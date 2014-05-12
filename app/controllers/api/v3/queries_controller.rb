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



module Api::V3
  class QueriesController < ApplicationController
    unloadable

    include ApiController
    include Concerns::ColumnData

    include QueriesHelper
    include ExtendedHTTP

    before_filter :find_optional_project
    before_filter :setup_query, only: [:available_columns, :custom_field_filters, :create]

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
      @query.save

      respond_to do |format|
        format.api
      end
    end

    def update
      @query.save

      respond_to do |format|
        format.api
      end
    end

    private

    # Note: Not dry - lifted straight from old queries controller
    def setup_query
      @query = Query.new params[:query] ? permitted_params.query : nil
      @query.project = @project unless params[:query_is_for_all]
      prepare_query @query
      @query.user = User.current
    end

    # Note: Not dry - lifted straight from old queries controller
    def prepare_query(query)
      @query.is_public = false unless User.current.allowed_to?(:manage_public_queries, @project) || User.current.admin?
      view_context.add_filter_from_params if params[:fields] || params[:f]
      @query.group_by ||= params[:group_by]
      @query.project = nil if params[:query_is_for_all]
      @query.display_sums ||= params[:display_sums].present?
      @query.column_names = params[:c] if params[:c]
      @query.column_names = nil if params[:default_columns]
      @query.name = params[:name] if params[:name]
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

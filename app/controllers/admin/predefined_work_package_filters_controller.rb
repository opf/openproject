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

class Admin::PredefinedWorkPackageFiltersController < ApplicationController
  include OpTurbo::ComponentStream
  include PaginationHelper
  include SortableLists::DropRequestValidation

  configure_drop_request list_type: PredefinedWorkPackageFilter::SORTABLE_LIST_TYPE, list_id_scoped: false

  layout "admin"
  menu_item :predefined_work_package_filters

  before_action :authorize_global
  before_action :find_filter, except: %i[index new create query_summary]

  def index
    @filters = PredefinedWorkPackageFilter.available.ordered
  end

  def new
    @filter = PredefinedWorkPackageFilter.new
    render :edit
  end

  def edit; end

  def create
    @filter = PredefinedWorkPackageFilter.new(filter_attributes)
    if @filter.save
      redirect_to configuration_admin_predefined_work_package_filter_path(@filter),
                  status: :see_other, notice: t(:notice_successful_create)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def update
    if @filter.update(filter_attributes)
      redirect_to edit_admin_predefined_work_package_filter_path(@filter),
                  status: :see_other, notice: t(:notice_successful_update)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def configuration
    prepare_query
  end

  def update_configuration
    @filter.query_properties = submitted_query_properties
    prepare_query

    if @query.valid? && @filter.save
      redirect_to configuration_admin_predefined_work_package_filter_path(@filter),
                  status: :see_other, notice: t(:notice_successful_update)
    else
      render :configuration, status: :unprocessable_entity
    end
  rescue JSON::ParserError, KeyError, TypeError
    head :bad_request
  end

  def query_summary
    filter = PredefinedWorkPackageFilter.new(query_properties: parse_query_properties(params.expect(:query_props)))
    query = WorkPackages::PredefinedFilterQuery.new(filter).configuration_query

    render turbo_stream: turbo_stream.update(
      "predefined-filter-query-summary",
      partial: "query_summary",
      locals: { query: }
    )
  rescue JSON::ParserError, KeyError, TypeError
    head :bad_request
  end

  def destroy
    @filter.remove!
    redirect_to admin_predefined_work_package_filters_path, status: :see_other
  end

  def move
    filters = PredefinedWorkPackageFilter.available
    unless valid_drop_request? && @filter.move_after_anchor(drop_params[:prev_id], scope: filters)
      return head :unprocessable_entity
    end

    update_via_turbo_stream(component: PredefinedWorkPackageFilters::TableComponent.new(rows: filters.ordered), method: :morph)
    respond_with_turbo_streams
  end

  def projects
    active_projects = @filter.active_projects
    @projects = active_projects.order(:name, :id).paginate(page: page_param, per_page: per_page_param)
    @candidate_projects = Project.active.where.not(id: active_projects.select(:id))
  end

  def add_projects
    projects = Project.active.where(id: selected_project_ids)
    @filter.with_lock do
      projects.find_each { |project| @filter.set_active_in!(project, active: true) }
    end
    redirect_to projects_admin_predefined_work_package_filter_path(@filter), status: :see_other
  end

  def remove_project
    project = Project.active.find(params.expect(:project_id))
    @filter.with_lock { @filter.set_active_in!(project, active: false) }
    redirect_to projects_admin_predefined_work_package_filter_path(@filter), status: :see_other
  end

  private

  def find_filter
    @filter = PredefinedWorkPackageFilter.available.find(params.expect(:id))
  end

  def prepare_query
    query = WorkPackages::PredefinedFilterQuery.new(@filter)
    @query_editor_properties = query.editor_properties
    @query = query.configuration_query
  end

  def filter_attributes
    params.expect(predefined_work_package_filter: %i[name placement])
  end

  def selected_project_ids
    Array(params.permit(project_ids: [])[:project_ids]).filter_map do |value|
      node = JSON.parse(value)
      Integer(node["nodeId"], exception: false) if node.is_a?(Hash)
    rescue JSON::ParserError, TypeError
      nil
    end
  end

  def submitted_query_properties
    payload = params[:query_props]
    return @filter.query_properties if payload.blank?

    properties = parse_query_properties(payload)
    defaults = WorkPackages::PredefinedFilterQuery.new(@filter).editor_properties
    properties == defaults ? @filter.query_properties : properties
  end

  def parse_query_properties(payload)
    properties = JSON.parse(payload)
    raise JSON::ParserError unless valid_editor_properties?(properties)

    properties
  end

  def valid_editor_properties?(properties)
    return false unless properties.is_a?(Hash)
    return false unless properties["g"].nil? || properties["g"].is_a?(String)
    return false unless properties["t"].nil? || properties["t"].is_a?(String)

    filters = properties["f"]
    filters.is_a?(Array) && filters.all? { |filter| valid_editor_filter?(filter) }
  end

  def valid_editor_filter?(filter)
    filter.is_a?(Hash) && filter["n"].is_a?(String) && filter["o"].is_a?(String) &&
      Array(filter["v"]).all? { |value| value.is_a?(String) || value.is_a?(Numeric) || value.in?([true, false]) }
  end
end

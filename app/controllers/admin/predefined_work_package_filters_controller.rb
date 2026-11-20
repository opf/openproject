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
  include SortableLists::DropRequestValidation

  configure_drop_request list_type: PredefinedWorkPackageFilter::SORTABLE_LIST_TYPE, list_id_scoped: false

  layout "admin"
  menu_item :predefined_work_package_filters

  before_action :authorize_global
  before_action :find_filter, except: %i[index new create]

  def index
    @filters = PredefinedWorkPackageFilter.available.ordered
  end

  def new
    @filter = PredefinedWorkPackageFilter.new
    prepare_query
    render :edit
  end

  def edit
    prepare_query
  end

  def create
    @filter = PredefinedWorkPackageFilter.new
    save_filter
  end

  def update
    save_filter
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
    @projects = Project.active.order(:name)
    @active_project_ids = @filter.project_settings.pluck(:project_id, :active).to_h
  end

  def update_projects
    selections = params.key?(:projects) ? params.expect(projects: {}) : {}
    @filter.with_lock do
      Project.active.where(id: selections.keys).find_each do |project|
        @filter.set_active_in!(project, active: selections[project.id.to_s] == "1")
      end
    end
    redirect_to projects_admin_predefined_work_package_filter_path(@filter), status: :see_other
  end

  private

  def find_filter
    @filter = PredefinedWorkPackageFilter.available.find(params.expect(:id))
  end

  def prepare_query
    query = WorkPackages::PredefinedFilterQuery.new(@filter)
    @query_editor_properties = query.editor_properties
    @query = query.build
  end

  def save_filter
    @filter.assign_attributes(filter_attributes)
    prepare_query
    if @query.valid? && @filter.save
      redirect_to admin_predefined_work_package_filters_path, status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  rescue JSON::ParserError, KeyError, TypeError
    head :bad_request
  end

  def filter_attributes
    params.expect(predefined_work_package_filter: %i[name project_overview work_packages gantt])
      .merge(query_properties: submitted_query_properties)
  end

  def submitted_query_properties
    payload = params[:query_props]
    return @filter.query_properties if payload.blank?

    properties = JSON.parse(payload)
    raise JSON::ParserError unless valid_editor_properties?(properties)

    defaults = WorkPackages::PredefinedFilterQuery.new(@filter).editor_properties
    properties == defaults ? @filter.query_properties : properties
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

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
    case params[:direction]
    when "up" then @filter.move_higher
    when "down" then @filter.move_lower
    else return head :bad_request
    end
    redirect_to admin_predefined_work_package_filters_path, status: :see_other
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
    @query = WorkPackages::PredefinedFilterQuery.new(@filter).build
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
    allowed = params.expect(predefined_work_package_filter: %i[name project_overview work_packages gantt group_by])
    allowed.except(:group_by).merge(
      query_properties: @filter.query_properties.merge("g" => submitted_group_by(allowed[:group_by]), "f" => submitted_filters)
    )
  end

  def submitted_group_by(group_by)
    API::Utilities::PropertyNameConverter.from_ar_name(group_by) if group_by.present?
  end

  def submitted_filters
    entries = JSON.parse(params.fetch(:filters, "[]").presence || "[]")
    raise JSON::ParserError unless entries.is_a?(Array)

    entries.map { |entry| submitted_filter(entry) }
  end

  def submitted_filter(entry)
    raise JSON::ParserError unless entry.is_a?(Hash) && entry.one?

    field, definition = entry.first
    raise JSON::ParserError unless definition.is_a?(Hash) && definition["values"].is_a?(Array)

    name = API::Utilities::PropertyNameConverter.from_ar_name(field)
    { "n" => name, "o" => definition.fetch("operator"), "v" => definition.fetch("values") }
  end
end

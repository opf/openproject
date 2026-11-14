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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

class Projects::Settings::WorkPackages::CustomFieldsController < Projects::SettingsController
  include OpTurbo::ComponentStream

  menu_item :settings_work_packages

  def show
    @query = custom_fields_query

    respond_to do |format|
      format.html
      format.turbo_stream do
        update_via_turbo_stream(component: overview_component)
        update_via_turbo_stream(component: Filter::FilterButtonComponent.new(query: @query))
        respond_with_turbo_streams
      end
    end
  end

  private

  def custom_fields_query
    ParamsToQueryService
      .new(WorkPackageCustomField, current_user, query_class: Queries::WorkPackageCustomFields::WorkPackageCustomFieldQuery)
      .call(params)
      .tap { |query| query.project = @project }
  end

  def overview_component
    Projects::Settings::WorkPackages::CustomFields::OverviewComponent.new(project: @project, query: @query)
  end
  helper_method :overview_component
end

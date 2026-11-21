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

module QueriesHelper
  def retrieve_query(project)
    query = if params[:query_id].present?
              Query.where(project:).find(params[:query_id])
            else
              Query.new_default(project:)
            end

    ::API::V3::UpdateQueryFromV3ParamsService
      .new(query, current_user)
      .call(params.permit!.to_h)

    query
  end

  def predefined_filter_view_data(project, placement)
    filter = predefined_filter_for_view(project, placement)
    return {} unless filter

    data = { predefined_filter_key: params[:name].to_s, predefined_filter_title: filter.display_name }
    if current_user.allowed_globally?(:manage_filters)
      data[:predefined_filter_configuration_path] = configuration_admin_predefined_work_package_filter_path(filter)
    end
    data
  end

  private

  def predefined_filter_for_view(project, placement)
    return if project.nil? || params[:query_id].present?

    filters = PredefinedWorkPackageFilter.active_in(project).at(placement)
    case (name = params[:name])
    when /\Apredefined_filter_\d+\z/
      filters.find_by(id: name.delete_prefix("predefined_filter_"))
    when String
      filters.find_by(builtin_key: name)
    when nil
      default_predefined_filter(filters, placement)
    end
  end

  def default_predefined_filter(filters, placement)
    filters.find_by(builtin_key: "all_open") if placement == :work_packages && params[:query_props].blank?
  end
end

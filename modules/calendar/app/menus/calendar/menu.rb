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

module Calendar
  class Menu < Submenu
    attr_reader :view_type, :project

    def initialize(project: nil, params: nil)
      @view_type = "work_packages_calendar"
      @project = project
      @params = params

      super(view_type:, project:, params:)
    end

    def default_queries
      project ? predefined_project_queries(:calendar) : []
    end

    def selected?(query_params)
      return query_params[:id].to_s == params[:id] if query_params.key?(:id)

      params[:id].blank? && query_params[:name] == params[:name]
    end

    def query_params(id)
      { id: }
    end

    def query_path(query_params)
      if query_params.key?(:query_props)
        new_project_calendar_path(project, query_params)
      else
        project_calendar_path(project, query_params)
      end
    end
  end
end

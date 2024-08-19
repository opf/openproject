# -- copyright
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
# ++
module Gantt
  class Menu < Submenu
    attr_reader :view_type, :project

    def initialize(project: nil, params: nil)
      @view_type = "gantt"
      @project = project
      @params = params

      super(view_type:, project:, params:)
    end

    def default_queries
      query_generator = Gantt::DefaultQueryGeneratorService.new(with_project: project)
      Gantt::DefaultQueryGeneratorService::QUERY_OPTIONS.filter_map do |query_key|
        params = query_generator.call(query_key:)
        next if params.nil?

        menu_item(
          title: I18n.t("js.work_packages.default_queries.#{query_key}"),
          query_params: params
        )
      end
    end

    def query_path(query_params)
      if project.present?
        project_gantt_index_path(project, params.permit(query_params.keys).merge!(query_params))
      else
        gantt_index_path(params.permit(query_params.keys).merge!(query_params))
      end
    end
  end
end

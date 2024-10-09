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
module WorkPackages
  class Menu < Submenu
    attr_reader :view_type, :project, :params

    def initialize(project: nil, params: nil)
      @view_type = "work_packages_table"

      super(view_type:, project:, params:)
    end

    def default_queries
      query_generator = WorkPackages::DefaultQueryGeneratorService.new(with_project: project)
      WorkPackages::DefaultQueryGeneratorService::QUERY_OPTIONS.filter_map do |query_key|
        params = query_generator.call(query_key:)
        next if params.nil?

        menu_item(
          title: I18n.t("js.work_packages.default_queries.#{query_key}"),
          query_params: params,
          show_enterprise_icon: params[:show_enterprise_icon].present?
        )
      end
    end

    def query_path(query_params)
      if query_params[:show_enterprise_icon].present?
        return ee_upsale_path(query_params)
      end

      if project.present?
        return report_project_work_packages_path(project, { name: query_params[:name] }) if query_params[:name] == :summary

        project_work_packages_path(project, query_params)
      else
        work_packages_path(query_params)
      end
    end

    def selected?(query_params)
      return true if check_for_redirected_urls(query_params)
      return true if highlight_on_work_packages?(query_params)

      super
    end

    def highlight_on_work_packages?(query_params)
      query_params[:work_package_default] &&
        (%i[filters query_props query_id name].none? { |k| params.key? k }) &&
        params[:on_work_package_path] == "true"
    end

    def ee_upsale_path(query_params)
      share_upsale_work_packages_path({ name: query_params[:name] })
    end

    def check_for_redirected_urls(query_params)
      # Special rules, as those are redirected to completely new pages where only the name parameter is preserved
      return true if query_params[:name] == :shared_with_me && params[:name] == "shared_with_me"
      return true if query_params[:name] == :shared_with_users && params[:name] == "shared_with_users"

      true if query_params[:name] == :summary && params[:name] == "summary"
    end
  end
end

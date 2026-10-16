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

module Grids::Configuration
  class InProjectBaseRegistration < ::Grids::Configuration::Registration
    widgets "work_packages_table",
            "work_packages_graph",
            "project_description",
            "project_status",
            "subprojects",
            "work_packages_calendar",
            "work_packages_overview",
            "time_entries_list",
            "members",
            "news",
            "documents",
            "custom_text"

    remove_query_lambda = -> {
      @query = ::Query.find_by(id: options["queryId"])

      next unless @query && QueryPolicy.new(User.current).allowed?(@query, :destroy)

      @query.destroy!
    }

    save_or_manage_queries_lambda = ->(user, project) {
      user.allowed_in_project?(:save_queries, project) &&
        user.allowed_in_project?(:manage_public_queries, project)
    }

    view_work_packages_lambda = ->(user, project) {
      user.allowed_in_any_work_package?(:view_work_packages, in_project: project)
    }

    widget_strategy "work_packages_table" do
      after_destroy remove_query_lambda

      allowed save_or_manage_queries_lambda

      options_representer "::API::V3::Grids::Widgets::QueryOptionsRepresenter"
    end

    widget_strategy "work_packages_graph" do
      after_destroy remove_query_lambda

      allowed save_or_manage_queries_lambda

      options_representer "::API::V3::Grids::Widgets::ChartOptionsRepresenter"
    end

    widget_strategy "custom_text" do
      options_representer "::API::V3::Grids::Widgets::CustomTextOptionsRepresenter"
    end

    widget_strategy "work_packages_overview" do
      allowed view_work_packages_lambda
    end

    widget_strategy "work_packages_calendar" do
      allowed view_work_packages_lambda
    end

    widget_strategy "members" do
      allowed ->(user, project) { user.allowed_in_project?(:view_members, project) }
    end

    widget_strategy "news" do
      allowed ->(user, project) { user.allowed_in_project?(:view_news, project) }
    end

    widget_strategy "documents" do
      allowed ->(user, project) { user.allowed_in_project?(:view_documents, project) }
    end

    macroed_getter_setter :view_permission
    macroed_getter_setter :edit_permission
    macroed_getter_setter :in_project_scope_path

    class << self
      def all_scopes
        view_allowed = if view_permission == :view_project
                         Project.visible(User.current)
                       else
                         Project.allowed_to(User.current, view_permission)
                       end

        projects = Project.where(id: view_allowed)

        projects.map { |p| url_helpers.send(to_scope, p) }
      end

      def from_scope(scope)
        # recognize_routes does not work with engine paths
        path = [OpenProject::Configuration.rails_relative_url_root,
                "projects",
                "([^/]+)",
                in_project_scope_path,
                "?"].flatten.compact.join("/")

        match = Regexp.new(path).match(scope)
        return if match.nil?

        {
          class: grid_class.constantize,
          project_id: match[1]
        }
      end

      def writable?(grid, user)
        super && user.allowed_in_project?(edit_permission, grid.project)
      end

      def visible(user = User.current)
        if view_permission == :view_project
          super.where(project_id: Project.visible(user))
        else
          super.where(project_id: Project.allowed_to(user, view_permission))
        end
      end
    end
  end
end

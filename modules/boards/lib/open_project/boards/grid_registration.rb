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

module OpenProject
  module Boards
    class GridRegistration < ::Grids::Configuration::Registration
      grid_class "Boards::Grid"
      to_scope :project_work_package_boards_path

      widgets "work_package_query"

      widget_strategy "work_package_query" do
        options_representer "::API::V3::Boards::Widgets::BoardOptionsRepresenter"
      end

      defaults -> {
        {
          row_count: 1,
          column_count: 4,
          widgets: []
        }
      }

      class << self
        def from_scope(scope)
          recognized = ::OpenProject::StaticRouting.recognize_route(scope)
          return if recognized.nil?

          if recognized[:controller] == "boards/boards"
            recognized.slice(:project_id, :id, :user_id)&.merge(class: ::Boards::Grid)
          end
        end

        def writable_scopes
          manage_allowed = Project.allowed_to(User.current, :manage_board_views)

          board_projects = Project.where(id: manage_allowed)

          board_projects.map { |p| url_helpers.project_work_package_boards_path(p) }
        end

        ##
        # Determines whether the given scope is writable by the current user
        def writable_scope?(scope)
          writable_scopes.include? scope
        end

        def all_scopes
          view_allowed = Project.allowed_to(User.current, :show_board_views)
          manage_allowed = Project.allowed_to(User.current, :manage_board_views)

          board_projects = Project
            .where(id: view_allowed)
            .or(Project.where(id: manage_allowed))

          board_projects.map { |p| url_helpers.project_work_package_boards_path(p) }
        end

        alias_method :super_visible, :visible

        def visible(user = User.current)
          in_project_with_permission(user, :show_board_views)
            .or(in_project_with_permission(user, :manage_board_views))
        end

        def writable?(model, user)
          super &&
            Project.allowed_to(user, :manage_board_views).exists?(model.project_id)
        end

        private

        def in_project_with_permission(user, permission)
          super_visible
            .where(project_id: Project.allowed_to(user, permission))
        end
      end

      private_class_method :super_visible
    end
  end
end

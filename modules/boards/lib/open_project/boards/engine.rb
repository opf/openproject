# OpenProject Boards module
#
# Copyright (C) the OpenProject GmbH
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

module OpenProject::Boards
  class Engine < ::Rails::Engine
    engine_name :openproject_boards

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-boards",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings: {} do
      project_module :board_view, dependencies: :work_package_tracking, order: 80 do
        permission :show_board_views,
                   { "boards/boards": %i[index show],
                     "boards/menus": %i[show] },
                   permissible_on: :project,
                   dependencies: :view_work_packages,
                   contract_actions: { boards: %i[read] }
        permission :manage_board_views,
                   { "boards/boards": %i[index show new create destroy] },
                   permissible_on: :project,
                   dependencies: :manage_public_queries,
                   contract_actions: { boards: %i[create update destroy] }
      end

      menu :project_menu,
           :boards,
           { controller: "/boards/boards", action: :index },
           caption: :"boards.label_boards",
           after: :work_packages,
           icon: "op-boards"

      menu :project_menu,
           :board_menu,
           { controller: "/boards/boards", action: :index },
           parent: :boards,
           partial: "boards/menus/menu",
           last: true,
           caption: :"boards.label_boards"

      should_render_global_menu_item = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
        User.current.allowed_in_any_project?(:show_board_views)
      end

      menu :top_menu,
           :boards,
           { controller: "/boards/boards", action: "index", project_id: nil },
           context: :modules,
           caption: :project_module_board_view,
           before: :news,
           after: :team_planners,
           icon: "op-boards",
           if: should_render_global_menu_item

      menu :global_menu,
           :boards,
           { controller: "/boards/boards", action: "index" },
           caption: :project_module_board_view,
           before: :news,
           after: :team_planners,
           icon: "op-boards",
           if: should_render_global_menu_item
    end

    patch_with_namespace :BasicData, :SettingSeeder

    config.to_prepare do
      OpenProject::Boards::GridRegistration.register!
    end
  end
end

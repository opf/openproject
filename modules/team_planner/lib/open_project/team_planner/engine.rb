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

module OpenProject::TeamPlanner
  class Engine < ::Rails::Engine
    engine_name :openproject_team_planner

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-team_planner",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings: {} do
      project_module :team_planner_view, dependencies: :work_package_tracking, enterprise_feature: true do
        permission :view_team_planner,
                   { "team_planner/team_planner": %i[index show upsale overview],
                     "team_planner/menus": %i[show] },
                   permissible_on: :project,
                   dependencies: %i[view_work_packages],
                   contract_actions: { team_planner: %i[read] }
        permission :manage_team_planner,
                   { "team_planner/team_planner": %i[index show new create destroy upsale] },
                   permissible_on: :project,
                   dependencies: %i[view_team_planner
                                    add_work_packages
                                    edit_work_packages
                                    save_queries
                                    manage_public_queries],
                   contract_actions: { team_planner: %i[create update destroy] }
      end

      should_render_global_menu_item = Proc.new do
        (User.current.logged? || !Setting.login_required?) &&
        User.current.allowed_in_any_project?(:view_team_planner)
      end

      menu :global_menu,
           :team_planners,
           { controller: "/team_planner/team_planner", action: :overview },
           caption: :"team_planner.label_team_planner_plural",
           before: :boards,
           after: :calendar_view,
           icon: "op-team-planner",
           if: should_render_global_menu_item,
           enterprise_feature: "team_planner_view"

      menu :project_menu,
           :team_planner_view,
           { controller: "/team_planner/team_planner", action: :index },
           caption: :"team_planner.label_team_planner_plural",
           after: :work_packages,
           icon: "op-team-planner",
           enterprise_feature: "team_planner_view"

      menu :project_menu,
           :team_planner_menu,
           { controller: "/team_planner/team_planner", action: :index },
           parent: :team_planner_view,
           partial: "team_planner/menus/menu",
           last: true,
           caption: :"team_planner.label_team_planner_plural"

      menu :top_menu,
           :team_planners, { controller: "/team_planner/team_planner", action: :overview },
           context: :modules,
           caption: :"team_planner.label_team_planner_plural",
           before: :boards,
           after: :calendar_view,
           icon: "op-team-planner",
           if: should_render_global_menu_item,
           enterprise_feature: "team_planner_view"
    end

    add_view :TeamPlanner,
             contract_strategy: "TeamPlanner::Views::ContractStrategy"
  end
end

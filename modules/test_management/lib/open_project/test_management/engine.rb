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

require "open_project/plugins"

module OpenProject::TestManagement
  class Engine < ::Rails::Engine
    engine_name :openproject_test_management

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-test_management",
             author_url: "https://www.openproject.org/",
             bundled: true,
             settings: {
               default: {
                 "default_display_prefix" => "TC"
               }
             } do
      project_module :test_management do
        permission :view_test_cases,
                   {
                     "test_management/test_cases": %i[index],
                     "test_management/menus": %i[show]
                   },
                   permissible_on: :project

        # shortcut: empty action maps until 1.2 wires case CRUD + folders
        permission :add_test_cases,
                   {},
                   permissible_on: :project,
                   require: :loggedin,
                   dependencies: :view_test_cases

        permission :edit_test_cases,
                   {},
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :delete_test_cases,
                   {},
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :manage_test_suites,
                   {},
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :manage_test_management,
                   { "test_management/project_settings": %i[show update] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases
      end

      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push :test_management,
                  { controller: "/test_management/test_cases", action: :index },
                  caption: :project_module_test_management,
                  after: :work_packages,
                  icon: "checklist",
                  if: ->(project) { project.module_enabled?(:test_management) }

        menu.push :test_management_menu,
                  { controller: "/test_management/menus", action: :show },
                  parent: :test_management,
                  partial: "test_management/menus/menu",
                  caption: :project_module_test_management,
                  if: ->(project) {
                    project.module_enabled?(:test_management) &&
                      TestManagement::ProjectSetting.for_project(project).vertical_navigation?
                  }

        menu.push :settings_test_management,
                  { controller: "/test_management/project_settings", action: :show },
                  caption: :project_module_test_management,
                  parent: :settings,
                  if: ->(project) {
                    User.current.allowed_in_project?(:manage_test_management, project)
                  }
      end

      menu :admin_menu,
           :test_management,
           { controller: "/test_management/admin/settings", action: :show },
           if: ->(_) { User.current.admin? },
           caption: :project_module_test_management,
           after: :admin_integrations,
           icon: "checklist"
    end

    patches %i[Project]

    # shortcut: no principal FK refs yet, add with case models in 1.2
  end
end

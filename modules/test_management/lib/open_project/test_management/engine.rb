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
                     "test_management/test_cases": %i[index show],
                     "test_management/suites": %i[index],
                     "test_management/menus": %i[show]
                   },
                   permissible_on: :project

        permission :add_test_cases,
                   { "test_management/test_cases": %i[new create] },
                   permissible_on: :project,
                   require: :loggedin,
                   dependencies: :view_test_cases

        permission :edit_test_cases,
                   { "test_management/test_cases": %i[edit update] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :delete_test_cases,
                   { "test_management/test_cases": %i[delete_dialog destroy] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :manage_test_suites,
                   { "test_management/suites": %i[index create update destroy] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :view_test_runs,
                   {
                     "test_management/test_runs": %i[index show],
                     "test_management/test_run_cases": %i[show],
                     "test_management/ci": %i[show]
                   },
                   permissible_on: :project,
                   dependencies: :view_test_cases

        permission :add_test_runs,
                   {
                     "test_management/test_runs": %i[new create edit update
                                                     complete_dialog complete
                                                     cancel_dialog cancel
                                                     reopen],
                     "test_management/test_run_iterations": %i[create],
                     "test_management/test_run_cases": %i[update]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_runs

        permission :execute_test_runs,
                   { "test_management/test_run_cases": %i[update] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_runs

        permission :delete_test_runs,
                   { "test_management/test_runs": %i[delete_dialog destroy] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_runs

        permission :upload_test_results,
                   {},
                   permissible_on: :project,
                   require: :loggedin,
                   dependencies: :view_test_runs

        permission :manage_test_ci,
                   {
                     "test_management/project_settings": %i[show],
                     "test_management/ci_connections": %i[create update destroy]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :trigger_test_automation,
                   { "test_management/ci_triggers": %i[new create] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :add_test_runs

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
                  if: ->(project) { project.module_enabled?(:test_management) }

        menu.push :settings_test_management,
                  { controller: "/test_management/project_settings", action: :show },
                  caption: :project_module_test_management,
                  parent: :settings,
                  if: ->(project) {
                    User.current.allowed_in_project?(:manage_test_management, project) ||
                      User.current.allowed_in_project?(:manage_test_ci, project)
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

    replace_principal_references "TestManagement::TestCase" => %i[author_id assigned_to_id updated_by_id],
                                 "TestManagement::TestRun" => %i[author_id assigned_to_id finished_by_id],
                                 "TestManagement::TestRunCase" => :assigned_to_id,
                                 "TestManagement::TestResult" => :user_id,
                                 "TestManagement::AutomationImport" => :user_id,
                                 "TestManagement::CiConnection" => :created_by_id,
                                 "TestManagement::TestRunIteration" => :created_by_id

    {
      project_test_management_settings: "projects/%s/test_management/settings",
      project_test_management_folders: "projects/%s/test_management/folders",
      project_test_management_cases: "projects/%s/test_management/cases",
      project_test_management_runs: "projects/%s/test_management/runs",
      project_test_management_ci_connections: "projects/%s/test_management/ci_connections",
      project_test_management_ci_triggers: "projects/%s/test_management/ci_triggers",
      project_test_management_automation_results: "projects/%s/test_management/automation/results",
      test_management_folder: "test_management/folders/%s",
      test_management_case: "test_management/cases/%s",
      test_management_run: "test_management/runs/%s",
      test_management_run_complete: "test_management/runs/%s/complete",
      test_management_run_cancel: "test_management/runs/%s/cancel",
      test_management_run_reopen: "test_management/runs/%s/reopen",
      test_management_run_imports: "test_management/runs/%s/imports",
      test_management_run_iterations: "test_management/runs/%s/iterations",
      test_management_run_case: "test_management/run_cases/%s",
      test_management_run_case_results: "test_management/run_cases/%s/results",
      test_management_result: "test_management/results/%s",
      test_management_import: "test_management/automation/imports/%s",
      test_management_ci_connection: "test_management/ci_connections/%s",
      test_management_assistant_providers: "test_management/assistant/providers",
      test_management_assistant_provider: "test_management/assistant/providers/%s",
      test_management_assistant_provider_default: "test_management/assistant/providers/%s/default",
      test_management_assistant_provider_test_connection: "test_management/assistant/providers/%s/test_connection"
    }.each do |name, template|
      add_api_path(name) { |*ids| "#{root}/#{template % ids}" }
    end

    add_api_path :project_test_management_run_results do |id, run_id|
      "#{root}/projects/#{id}/test_management/runs/#{run_id}/results"
    end

    add_api_path :test_management_run_iteration do |id, number|
      "#{root}/test_management/runs/#{id}/iterations/#{number}"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::TestManagement::TestManagementAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::TestManagement::AutomationByProjectAPI
    end
  end
end

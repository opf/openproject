# frozen_string_literal: true

require "open_project/plugins"
require_relative "patches/api/work_package_representer"

module OpenProject::TestManagement
  class Engine < ::Rails::Engine
    engine_name :openproject_test_management

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-test_management",
             author_url: "https://www.openproject.org/",
             bundled: true,
             settings: {
               default: {
                 "default_display_prefix" => "TC",
                 "hotkeys_enabled" => true,
                 "hotkey_hints_enabled" => true
               }
             } do
      project_module :test_management do
        permission :view_test_cases,
                   {
                     "test_management/test_cases": %i[index show],
                     "test_management/suites": %i[index],
                     "test_management/menus": %i[show],
                     "test_management/placeholders": %i[show],
                     "test_management/exports": %i[test_cases]
                   },
                   permissible_on: :project
        # manage_test_management covers project settings (including folder tree layout)

        permission :add_test_cases,
                   {
                     "test_management/test_cases": %i[new create],
                     "test_management/test_cases/bulk": %i[copy]
                   },
                   permissible_on: :project,
                   require: :loggedin,
                   dependencies: :view_test_cases

        permission :edit_test_cases,
                   {
                     "test_management/test_cases": %i[edit update restore],
                     "test_management/test_cases/bulk": %i[edit update move]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :change_test_case_status,
                   {
                     "test_management/test_cases": %i[update],
                     "test_management/test_cases/bulk": %i[edit update]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :delete_test_cases,
                   {
                     "test_management/test_cases": %i[delete_dialog destroy],
                     "test_management/test_cases/bulk": %i[delete_dialog destroy]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :manage_test_suites,
                   {
                     "test_management/suites": %i[index create update destroy]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :view_test_plans,
                   {
                     "test_management/test_plans": %i[index show],
                     "test_management/exports": %i[test_plan]
                   },
                   permissible_on: :project,
                   dependencies: :view_test_cases

        permission :manage_test_plans,
                   {
                     "test_management/test_plans": %i[new create edit update destroy complete reopen rerun],
                     "test_management/test_plan_entries": %i[create update destroy]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_plans

        permission :view_test_runs,
                   {
                     "test_management/test_runs": %i[index show],
                     "test_management/test_run_cases": %i[show],
                     "test_management/milestones": %i[index show],
                     "test_management/placeholders": %i[show],
                     "test_management/exports": %i[test_run milestone]
                   },
                   permissible_on: :project,
                   dependencies: :view_test_cases

        permission :manage_test_milestones,
                   {
                     "test_management/milestones": %i[new create edit update destroy start complete reopen]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_runs

        permission :add_test_runs,
                   {
                     "test_management/test_runs": %i[new create edit update
                                                     complete_dialog complete
                                                     cancel_dialog cancel
                                                     reopen],
                     "test_management/test_run_iterations": %i[create],
                     "test_management/test_run_cases": %i[update],
                     "test_management/test_run_attachments": %i[create destroy],
                     "test_management/placeholders": %i[show]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_runs

        permission :execute_test_runs,
                   {
                     "test_management/test_run_cases": %i[update],
                     "test_management/test_run_attachments": %i[create destroy],
                     "test_management/placeholders": %i[show]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_runs

        permission :delete_test_runs,
                   {
                     "test_management/test_runs": %i[delete_dialog destroy]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_runs

        permission :upload_test_results,
                   {
                     "test_management/test_runs": %i[complete_dialog complete]
                   },
                   permissible_on: :project,
                   require: :loggedin,
                   dependencies: :view_test_runs

        permission :manage_test_ci,
                   {
                     "test_management/placeholders": %i[show],
                     "test_management/project_settings": %i[show],
                     "test_management/ci_connections": %i[create update destroy check]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :trigger_test_automation,
                   {
                     "test_management/ci_triggers": %i[new create],
                     "test_management/placeholders": %i[show]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :add_test_runs

        permission :manage_test_management,
                   {
                     "test_management/project_settings": %i[show update],
                     "test_management/labels": %i[create update destroy],
                     "test_management/configuration_groups": %i[create update destroy],
                     "test_management/configurations": %i[create update destroy]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        permission :show_testing_content,
                   { "test_management/work_package_testing_tab": %i[index count] },
                   permissible_on: %i[work_package project],
                   dependencies: :view_test_cases

        permission :link_test_cases_to_work_packages,
                   {
                     "test_management/test_cases": %i[edit update]
                   },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_test_cases

        # Test Assistant (0014). Saving drafts / confirmed chat actions additionally need the
        # permission of the action itself (add_test_cases, add_test_runs, manage_test_milestones).
        permission :use_test_assistant,
                   { "test_management/assistant": %i[show select_provider generate generation generation_status
                                                     cancel_generation retry_generation save_drafts chat confirm
                                                     cancel clear] },
                   permissible_on: :project,
                   require: :loggedin,
                   dependencies: :view_test_cases
      end

      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push :test_management,
                  { controller: "/test_management/test_cases", action: :index },
                  caption: :project_module_test_management,
                  after: :work_packages,
                  icon: "checklist",
                  if: ->(project) { project.module_enabled?(:test_management) }

        # One child entry with a partial (0018), like Documents and Meetings: the main menu shows
        # the "→" arrow, the sidebar the "← Test management" header and the section list
        # (TestManagement::Menu, loaded into a turbo frame). Section visibility (permissions, the
        # Test Assistant and Milestones switches) is decided there.
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

      menu :work_package_split_view,
           :testing,
           { tab: :testing },
           skip_permissions_check: true,
           after: :relations,
           if: ->(project) {
             project&.module_enabled?(:test_management) &&
               User.current.allowed_in_project?(:show_testing_content, project)
           },
           badge: ->(work_package:, **) {
             TestManagement::WorkPackageTesting.count_for(work_package)
           },
           caption: :"test_management.work_package_tab.title"

      menu :admin_menu,
           :test_management,
           { controller: "/test_management/admin/settings", action: :show },
           if: ->(_) { User.current.admin? },
           caption: :project_module_test_management,
           after: :admin_integrations,
           icon: "checklist"
    end

    patches %i[Project WorkPackage]

    replace_principal_references "TestManagement::TestCase" => %i[author_id assigned_to_id updated_by_id],
                                 "TestManagement::TestCaseEvent" => :user_id,
                                 "TestManagement::TestRun" => %i[author_id assigned_to_id finished_by_id],
                                 "TestManagement::TestRunCase" => :assigned_to_id,
                                 "TestManagement::TestResult" => :user_id,
                                 "TestManagement::AutomationImport" => :user_id,
                                 "TestManagement::CiConnection" => :created_by_id,
                                 "TestManagement::TestRunIteration" => :created_by_id,
                                 "TestManagement::Milestone" => :created_by_id,
                                 "TestManagement::TestPlan" => %i[author_id assigned_to_id finished_by_id],
                                 "TestManagement::TestPlanEntry" => :assigned_to_id

    # Keyboard shortcuts (0019): layout hook, required like the Backlogs hooks.
    config.to_prepare do
      require "open_project/test_management/hooks/hotkeys_hook"
    end

    # Work package "Testing" tab: `_links.testing` makes the Angular tab
    # displayable (full view); the menu entry adds it to the split view tab bar.
    extend_api_response(:v3, :work_packages, :work_package,
                        &::OpenProject::TestManagement::Patches::API::WorkPackageRepresenter.extension)

    # --- APIv3 (0008): automation ingest + runs, run cases, imports, attachments
    add_api_path :project_test_management_automation_results do |id|
      "#{root}/projects/#{id}/test_management/automation/results"
    end

    add_api_path :project_test_management_runs do |id|
      "#{root}/projects/#{id}/test_management/runs"
    end

    add_api_path :project_test_management_run_results do |id, run_id|
      "#{root}/projects/#{id}/test_management/runs/#{run_id}/results"
    end

    add_api_path :test_management_run do |id|
      "#{root}/test_management/runs/#{id}"
    end

    %i[complete cancel imports attachments].each do |action|
      add_api_path :"test_management_run_#{action}" do |id|
        "#{root}/test_management/runs/#{id}/#{action}"
      end
    end

    add_api_path :test_management_run_case do |id|
      "#{root}/test_management/run_cases/#{id}"
    end

    add_api_path :test_management_run_case_results do |id|
      "#{root}/test_management/run_cases/#{id}/results"
    end

    add_api_path :test_management_result do |id|
      "#{root}/test_management/results/#{id}"
    end

    add_api_path :test_management_run_case_attachments do |id|
      "#{root}/test_management/run_cases/#{id}/attachments"
    end

    # --- APIv3 (0009): CI connections + iterations
    add_api_path :project_test_management_ci_connections do |id|
      "#{root}/projects/#{id}/test_management/ci_connections"
    end

    add_api_path :test_management_ci_connection do |id|
      "#{root}/test_management/ci_connections/#{id}"
    end

    add_api_path :test_management_run_iterations do |id|
      "#{root}/test_management/runs/#{id}/iterations"
    end

    add_api_path :test_management_run_iteration do |id, number|
      "#{root}/test_management/runs/#{id}/iterations/#{number}"
    end

    add_api_path :project_test_management_ci_triggers do |id|
      "#{root}/projects/#{id}/test_management/ci_triggers"
    end

    add_api_path :project_test_management_assistant_generations do |id|
      "#{root}/projects/#{id}/test_management/assistant/generations"
    end

    add_api_path :test_management_assistant_generation do |id|
      "#{root}/test_management/assistant/generations/#{id}"
    end

    add_api_path :test_management_assistant_generation_save do |id|
      "#{root}/test_management/assistant/generations/#{id}/save"
    end

    # --- APIv3 (0021): saved AI providers of the Test Assistant
    add_api_path :test_management_assistant_providers do
      "#{root}/test_management/assistant/providers"
    end

    add_api_path :test_management_assistant_provider do |id|
      "#{root}/test_management/assistant/providers/#{id}"
    end

    add_api_path :test_management_assistant_provider_default do |id|
      "#{root}/test_management/assistant/providers/#{id}/default"
    end

    add_api_path :test_management_import do |id|
      "#{root}/test_management/automation/imports/#{id}"
    end

    # --- APIv3 (0012): milestones
    add_api_path :project_test_management_milestones do |id|
      "#{root}/projects/#{id}/test_management/milestones"
    end

    add_api_path :test_management_milestone do |id|
      "#{root}/test_management/milestones/#{id}"
    end

    %i[start complete reopen].each do |action|
      add_api_path :"test_management_milestone_#{action}" do |id|
        "#{root}/test_management/milestones/#{id}/#{action}"
      end
    end

    # --- APIv3: configurations and test plans
    add_api_path :project_test_management_configuration_groups do |id|
      "#{root}/projects/#{id}/test_management/configuration_groups"
    end

    add_api_path :test_management_configuration_group do |id|
      "#{root}/test_management/configuration_groups/#{id}"
    end

    add_api_path :test_management_configuration do |id|
      "#{root}/test_management/configurations/#{id}"
    end

    add_api_path :project_test_management_plans do |id|
      "#{root}/projects/#{id}/test_management/plans"
    end

    add_api_path :test_management_plan do |id|
      "#{root}/test_management/plans/#{id}"
    end

    %i[complete reopen rerun].each do |action|
      add_api_path :"test_management_plan_#{action}" do |id|
        "#{root}/test_management/plans/#{id}/#{action}"
      end
    end

    add_api_path :test_management_plan_entries do |id|
      "#{root}/test_management/plans/#{id}/entries"
    end

    add_api_path :test_management_plan_entry do |plan_id, id|
      "#{root}/test_management/plans/#{plan_id}/entries/#{id}"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::TestManagement::TestManagementAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::TestManagement::AutomationByProjectAPI
    end
  end
end

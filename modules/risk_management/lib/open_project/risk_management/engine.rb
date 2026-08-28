# frozen_string_literal: true

require "open_project/plugins"

module OpenProject
  module RiskManagement
    class Engine < ::Rails::Engine
      engine_name :openproject_risk_management

      include OpenProject::Plugins::ActsAsOpEngine

      def self.settings
        {
          default: {
            "impact_very_low_max" => 10_000,
            "impact_low_max" => 50_000,
            "impact_medium_max" => 100_000,
            "impact_high_max" => 500_000
          }
        }
      end

      initializer "risk_management.menu" do
        ::Redmine::MenuManager.map(:project_menu) do |menu|
          menu.push :risk_log,
                    { controller: "/risk_management/risk_logs", action: "index" },
                    after: :overview,
                    caption: :"risk_management.risk_log.label",
                    icon: "shield"

          menu.push :risk_log_menu,
                    { controller: "/risk_management/risk_logs", action: "index" },
                    parent: :risk_log,
                    partial: "risk_management/menus/menu",
                    last: true,
                    caption: :"risk_management.risk_log.label"
        end
      end

      initializer "risk_management.event_subscriptions" do
        Rails.application.config.after_initialize do
          OpenProject::Notifications.subscribe(OpenProject::Events::MODULE_ENABLED) do |payload|
            enabled_module = payload[:enabled_module]
            next unless enabled_module.name == "risk_log"

            OpenProject::RiskManagement::Engine.synchronize_risk_type(enabled_module.project, enabled: true)
          end

          OpenProject::Notifications.subscribe(OpenProject::Events::MODULE_DISABLED) do |payload|
            disabled_module = payload[:disabled_module]
            next unless disabled_module.name == "risk_log"

            OpenProject::RiskManagement::Engine.synchronize_risk_type(disabled_module.project, enabled: false)
          end
        end
      end

      config.to_prepare do
        %i[
          risk_owner risk_likelihood risk_impact risk_exposure risk_category_ids risk_response
        ].each do |attribute|
          TypeVariant.add_constraint(
            attribute,
            ->(variant, **) { variant.type.builtin_identifier == "risk" }
          )
        end

        patch = ::RiskManagement::Patches::WorkPackagesDialogsCreateForm
        form = ::WorkPackages::Dialogs::CreateForm
        form.prepend(patch) unless form < patch

        dialog_patch = ::RiskManagement::Patches::WorkPackagesDialogsCreateDialogComponent
        dialog = ::WorkPackages::Dialogs::CreateDialogComponent
        dialog.prepend(dialog_patch) unless dialog < dialog_patch
      end

      def self.synchronize_risk_type(project, enabled:)
        configuration = ::RiskManagement::Configuration.load
        risk_type = configuration.risk_type
        return if project.nil? || risk_type.nil?

        if enabled
          project.project_types.find_or_create_by!(type: risk_type) do |project_type|
            project_type.variant = risk_type.default_variant
          end
        else
          project.project_types.where(type: risk_type).destroy_all
        end
      end

      register(
        "openproject-risk_management",
        author_url: "https://www.openproject.org/",
        bundled: true,
        settings:
      ) do
        project_module :risk_log, dependencies: :work_package_tracking do
          permission :view_risk_log,
                     {
                       "risk_management/risk_logs": %i[index details],
                       "risk_management/plans": %i[show]
                     },
                     permissible_on: :project,
                     dependencies: :view_work_packages

          permission :manage_risk_management_plan,
                     { "risk_management/plans": %i[edit update] },
                     permissible_on: :project,
                     dependencies: :view_risk_log
        end

        ::Redmine::MenuManager.map(:admin_menu) do |menu|
          menu.push :risk_management_settings,
                    { controller: "/risk_management/admin/settings", action: "show" },
                    parent: :admin_work_packages,
                    if: ->(_) { User.current.admin? },
                    caption: :"risk_management.label"
        end
      end
    end
  end
end

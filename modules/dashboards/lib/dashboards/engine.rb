# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require "open_project/plugins"

module Dashboards
  class Engine < ::Rails::Engine
    engine_name :dashboards

    include OpenProject::Plugins::ActsAsOpEngine

    initializer "dashboards.menu" do
      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:dashboards,
                  { controller: "/dashboards/dashboards", action: "show" },
                  caption: :"dashboards.label",
                  after: :work_packages,
                  icon: "meter",
                  badge: "label_menu_badge.alpha")
      end
    end

    initializer "dashboards.permissions" do
      Rails.application.reloader.to_prepare do
        OpenProject::AccessControl.map do |ac_map|
          ac_map.project_module(:dashboards) do |pm_map|
            pm_map.permission(:view_dashboards,
                              { "dashboards/dashboards": %i[show] },
                              permissible_on: :project)
            pm_map.permission(:manage_dashboards,
                              { "dashboards/dashboards": %i[show] },
                              permissible_on: :project)
          end
        end
      end
    end

    initializer "dashboards.conversion" do
      require Rails.root.join("config/constants/ar_to_api_conversions")

      Constants::ARToAPIConversions.add("grids/dashboard": "grid")
    end

    config.to_prepare do
      Dashboards::GridRegistration.register!
    end
  end
end

# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require 'open_project/plugins'

module Dashboards
  class Engine < ::Rails::Engine
    isolate_namespace Dashboards

    engine_name :dashboards

    include OpenProject::Plugins::ActsAsOpEngine

    initializer 'dashboards.menu' do
      ::Redmine::MenuManager.map(:project_menu) do |menu|
        menu.push(:dashboards,
                  { controller: 'dashboards/dashboards', action: 'show' },
                  caption: :'dashboards.label',
                  after: :work_packages,
                  before: :calendar,
                  param: :project_id,
                  engine: :project_dashboards,
                  icon: 'icon2 icon-status',
                  badge: 'dashboards.menu_badge')
      end
    end

    initializer 'dashboards.menu' do
      OpenProject::AccessControl.map do |ac_map|
        ac_map.project_module(:dashboards) do |pm_map|
          pm_map.permission(:view_dashboards, 'dashboards/dashboards': ['show'])
          pm_map.permission(:manage_dashboards, 'dashboards/dashboards': ['show'])
        end
      end
    end

    config.to_prepare do
      Dashboards::GridRegistration.register!
    end
  end
end

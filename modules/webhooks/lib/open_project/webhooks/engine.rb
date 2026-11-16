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

module OpenProject::Webhooks
  class Engine < ::Rails::Engine
    engine_name :openproject_webhooks

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-webhooks",
             bundled: true,
             author_url: "https://www.openproject.org" do
      menu :admin_menu,
           :plugin_webhooks,
           { controller: "/webhooks/outgoing/admin", action: :index },
           if: Proc.new { User.current.admin? },
           parent: :api_and_webhooks,
           caption: :"webhooks.plural"

      menu :admin_menu,
           :plugin_webhooks_kubernetes_connections,
           { controller: "/webhooks/kubernetes/connections", action: :index },
           if: Proc.new { User.current.admin? },
           parent: :api_and_webhooks,
           caption: :"webhooks.kubernetes.connections.plural"

      menu :admin_menu,
           :plugin_webhooks_kubernetes_scripts,
           { controller: "/webhooks/kubernetes/scripts", action: :index },
           if: Proc.new { User.current.admin? },
           parent: :api_and_webhooks,
           caption: :"webhooks.kubernetes.scripts.plural"

      project_module nil do
        permission :manage_project_scripts,
                   { "projects/settings/kubernetes_scripts": %i[show update] },
                   permissible_on: :project,
                   require: :member
      end

      project_module :work_package_tracking do
        permission :run_manual_scripts,
                   { "webhooks/manual_scripts": %i[menu new create show] },
                   permissible_on: %i[work_package project],
                   dependencies: %i[view_work_packages]
      end

      menu :project_menu,
           :settings_kubernetes_scripts,
           { controller: "/projects/settings/kubernetes_scripts", action: :show },
           caption: :"webhooks.kubernetes.project_settings.title",
           parent: :settings,
           before: :settings_storage
    end

    initializer "webhooks.subscribe_to_notifications" do |app|
      app.config.after_initialize do
        ::OpenProject::Webhooks::EventResources.subscribe!
      end
    end

    add_cron_jobs do
      {
        CleanupWebhookLogsJob: {
          cron: "28 5 * * 7", # runs at 5:28 on Sunday
          class: ::CleanupWebhookLogsJob.name
        }
      }
    end
  end
end

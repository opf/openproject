# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2023 Ben Tey
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require "open_project/plugins"

require_relative "notification_handlers"
require_relative "hook_handler"
require_relative "services"

module OpenProject::GitlabIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_gitlab_integration

    include OpenProject::Plugins::ActsAsOpEngine

    # The repositories module's FillFromGitlab migration reads these settings (including ENV overrides).
    # Keep at least this settings registration around until that migration is squashed.
    #
    # TODO: webhook_secret should be marked as `secret: true`, but that is only supported
    # for string settings, not for keys inside this plugin settings hash.
    def self.settings
      {
        default: {
          "gitlab_user_id" => nil,
          "webhook_secret" => nil
        }
      }
    end

    register "openproject-gitlab_integration",
             author_url: "https://github.com/btey/openproject",
             bundled: true,
             settings: do
      ::Redmine::MenuManager.map(:admin_menu) do |menu|
        menu.push :admin_gitlab_integration,
                  { controller: "/gitlab_integration/admin/settings", action: "show" },
                  parent: :admin_integrations,
                  if: ->(_) { User.current.admin? },
                  caption: "GitLab",
                  icon: :"op-logo-gitlab"
      end
    end

    patches %w[WorkPackage]

    initializer "gitlab.register_hook" do
      ::OpenProject::Webhooks.register_hook "gitlab" do |hook, environment, params, user|
        HookHandler.new.process(hook, environment, params, user)
      end
    end

    initializer "gitlab.subscribe_to_notifications" do
      ::OpenProject::Notifications.subscribe("gitlab.merge_request_hook") do |payload|
        NotificationHandlers.merge_request_hook(payload)
      end
      ::OpenProject::Notifications.subscribe("gitlab.note_hook") { |payload| NotificationHandlers.note_hook(payload) }
      ::OpenProject::Notifications.subscribe("gitlab.issue_hook") { |payload| NotificationHandlers.issue_hook(payload) }
      ::OpenProject::Notifications.subscribe("gitlab.push_hook") { |payload| NotificationHandlers.push_hook(payload) }
      ::OpenProject::Notifications.subscribe("gitlab.pipeline_hook") { |payload| NotificationHandlers.pipeline_hook(payload) }
    end

    add_cron_jobs do
      {
        "Cron::ClearOldMergeRequestsJob": {
          cron: "25 1 * * *", # runs at 1:25 nightly
          class: ::Cron::ClearOldMergeRequestsJob.name
        }
      }
    end
  end
end

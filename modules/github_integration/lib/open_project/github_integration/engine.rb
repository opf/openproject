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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "open_project/plugins"
require_relative "patches/api/work_package_representer"

module OpenProject::GithubIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_github_integration

    include OpenProject::Plugins::ActsAsOpEngine

    def self.settings
      {
        default: {
          "github_user_id" => nil
        }
      }
    end

    initializer "github.feature_decisions" do
      OpenProject::FeatureDecisions.add :deploy_targets
    end

    register(
      "openproject-github_integration",
      author_url: "https://www.openproject.org/",
      bundled: true,
      settings:
    ) do
      ::Redmine::MenuManager.map(:admin_menu) do |menu|
        menu.push :admin_github_integration,
                  { controller: "/deploy_targets", action: "index" },
                  if: Proc.new { OpenProject::FeatureDecisions.deploy_targets_active? && User.current.admin? },
                  caption: :label_github_integration,
                  icon: "mark-github"
      end

      project_module(:github, dependencies: :work_package_tracking) do
        permission(:show_github_content,
                   {},
                   permissible_on: %i[work_package project])

        permission :introspection,
                   {
                     admin: %i[info]
                   },
                   permissible_on: :global,
                   require: :loggedin,
                   enabled: -> { OpenProject::FeatureDecisions.deploy_targets_active? } # can only be enable at start-time
      end

      menu :work_package_split_view,
           :github,
           { tab: :github },
           if: ->(project) {
             User.current.allowed_in_project?(:show_github_content, project)
           },
           skip_permissions_check: true,
           badge: ->(work_package:, **) {
             work_package.github_pull_requests.count
           },
           caption: :project_module_github
    end

    initializer "github.register_hook" do
      ::OpenProject::Webhooks.register_hook "github" do |hook, environment, params, user|
        HookHandler.new.process(hook, environment, params, user)
      end
    end

    initializer "github.subscribe_to_notifications" do |app|
      app.config.after_initialize do
        ::OpenProject::Notifications.subscribe("github.check_run",
                                               &NotificationHandler.method(:check_run))
        ::OpenProject::Notifications.subscribe("github.issue_comment",
                                               &NotificationHandler.method(:issue_comment))
        ::OpenProject::Notifications.subscribe("github.pull_request",
                                               &NotificationHandler.method(:pull_request))
      end
    end

    extend_api_response(:v3, :root) do
      property :core_sha,
               exec_context: :decorator,
               getter: ->(*) { OpenProject::VERSION.core_sha },
               if: ->(*) { current_user.admin? || current_user.allowed_globally?(:introspection) }
    end

    extend_api_response(:v3, :work_packages, :work_package,
                        &::OpenProject::GithubIntegration::Patches::API::WorkPackageRepresenter.extension)

    add_api_path :github_pull_requests_by_work_package do |id|
      "#{work_package(id)}/github_pull_requests"
    end

    add_api_path :github_user do |id|
      "github_users/#{id}"
    end

    add_api_path :github_check_run do |id|
      "github_check_run/#{id}"
    end

    add_api_endpoint "API::V3::WorkPackages::WorkPackagesAPI", :id do
      mount ::API::V3::GithubPullRequests::GithubPullRequestsByWorkPackageAPI
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::GithubPullRequests::GithubPullRequestsAPI
    end

    add_cron_jobs do
      jobs = {
        "Cron::ClearOldPullRequestsJob": {
          cron: "25 1 * * *", # runs at 1:25 nightly
          class: ::Cron::ClearOldPullRequestsJob.name
        }
      }

      # Enabling the feature flag at runtime won't enable
      # the cron job. So if you want this feature, enable it
      # at start-time.
      if OpenProject::FeatureDecisions.deploy_targets_active?
        jobs[:"Cron::CheckDeployStatusJob"] = {
          cron: "15,45 * * * *", # runs every half hour
          class: ::Cron::CheckDeployStatusJob.name
        }
      end

      jobs
    end
  end
end

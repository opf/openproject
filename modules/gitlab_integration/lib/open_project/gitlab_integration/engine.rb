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

require_relative "patches/api/work_package_representer"
require_relative "notification_handlers"
require_relative "hook_handler"
require_relative "services"

module OpenProject::GitlabIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_gitlab_integration

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-gitlab_integration",
             author_url: "https://github.com/btey/openproject",
             bundled: true do
      project_module(:gitlab, dependencies: :work_package_tracking) do
        permission(:show_gitlab_content,
                   {},
                   permissible_on: %i[work_package project])
      end

      menu :work_package_split_view,
           :gitlab,
           { tab: :gitlab },
           if: ->(project) {
             User.current.allowed_in_project?(:show_gitlab_content, project)
           },
           skip_permissions_check: true,
           badge: ->(work_package:, **) {
             work_package.gitlab_merge_requests.count +
               work_package.gitlab_issues.count
           },
           caption: :project_module_github
    end

    patches %w[WorkPackage]

    initializer "gitlab.register_hook" do
      ::OpenProject::Webhooks.register_hook "gitlab" do |hook, environment, params, user|
        HookHandler.new.process(hook, environment, params, user)
      end
    end

    initializer "gitlab.subscribe_to_notifications" do
      ::OpenProject::Notifications.subscribe("gitlab.merge_request_hook",
                                             &NotificationHandlers.method(:merge_request_hook))
      ::OpenProject::Notifications.subscribe("gitlab.note_hook",
                                             &NotificationHandlers.method(:note_hook))
      ::OpenProject::Notifications.subscribe("gitlab.issue_hook",
                                             &NotificationHandlers.method(:issue_hook))
      ::OpenProject::Notifications.subscribe("gitlab.push_hook",
                                             &NotificationHandlers.method(:push_hook))
      ::OpenProject::Notifications.subscribe("gitlab.pipeline_hook",
                                             &NotificationHandlers.method(:pipeline_hook))
      ::OpenProject::Notifications.subscribe("gitlab.system_hook",
                                             &NotificationHandlers.method(:system_hook))
    end

    extend_api_response(:v3, :work_packages, :work_package,
                        &::OpenProject::GitlabIntegration::Patches::API::WorkPackageRepresenter.extension)

    add_api_path :gitlab_merge_requests_by_work_package do |id|
      "#{work_package(id)}/gitlab_merge_requests"
    end

    add_api_path :gitlab_issues_by_work_package do |id|
      "#{work_package(id)}/gitlab_issues"
    end

    add_api_path :gitlab_user do |id|
      "gitlab_users/#{id}"
    end

    add_api_path :gitlab_pipeline do |id|
      "gitlab_pipeline/#{id}"
    end

    add_api_endpoint "API::V3::WorkPackages::WorkPackagesAPI", :id do
      mount ::API::V3::GitlabMergeRequests::GitlabMergeRequestsByWorkPackageAPI
    end

    add_api_endpoint "API::V3::WorkPackages::WorkPackagesAPI", :id do
      mount ::API::V3::GitlabIssues::GitlabIssuesByWorkPackageAPI
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

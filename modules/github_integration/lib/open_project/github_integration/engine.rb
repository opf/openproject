#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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

require 'open_project/plugins'

require_relative './patches/api/work_package_representer'
require_relative './notification_handler'
require_relative './hook_handler'
require_relative './services'

module OpenProject::GithubIntegration
  class Engine < ::Rails::Engine
    engine_name :openproject_github_integration

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-github_integration',
             author_url: 'https://www.openproject.org/',
             bundled: true

    initializer 'github.register_hook' do
      ::OpenProject::Webhooks.register_hook 'github' do |hook, environment, params, user|
        HookHandler.new.process(hook, environment, params, user)
      end
    end

    initializer 'github.subscribe_to_notifications' do
      ::OpenProject::Notifications.subscribe('github.check_run',
                                             &NotificationHandler.method(:check_run))
      ::OpenProject::Notifications.subscribe('github.issue_comment',
                                             &NotificationHandler.method(:issue_comment))
      ::OpenProject::Notifications.subscribe('github.pull_request',
                                             &NotificationHandler.method(:pull_request))
    end

    initializer 'github.permissions' do
      OpenProject::AccessControl.map do |ac_map|
        ac_map.project_module(:github, dependencies: :work_package_tracking) do |pm_map|
          pm_map.permission(:show_github_content, {}, {})
        end
      end
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

    add_api_endpoint 'API::V3::WorkPackages::WorkPackagesAPI', :id do
      mount ::API::V3::GithubPullRequests::GithubPullRequestsByWorkPackageAPI
    end

    config.to_prepare do
      # Register the cron job to clean up old github pull requests
      ::Cron::CronJob.register! ::Cron::ClearOldPullRequestsJob
    end
  end
end

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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

# Prevent load-order problems in case openproject-plugins is listed after a plugin in the Gemfile
# or not at all
require "open_project/plugins"

module OpenProject::Repositories
  class Engine < ::Rails::Engine
    engine_name :openproject_repositories

    include OpenProject::Plugins::ActsAsOpEngine

    register "openproject-repositories", author_url: "https://openproject.org", bundled: true do
      menu :work_package_split_view,
           :repositories,
           { tab: :repositories },
           if: ->(project) {
             Repositories::Provider.exists? &&
               User.current.allowed_in_project?(:show_repository_content, project)
           },
           skip_permissions_check: true,
           badge: ->(work_package:, **) {
             work_package.repository_merge_requests.count +
             work_package.repository_issues.count +
             work_package.repository_branches.count +
             work_package.repository_commits.count
           },
           before: :watchers

      menu :admin_menu,
           :repository_providers,
           { controller: "/repositories/admin/repository_providers", action: :index },
           parent: :admin_integrations,
           if: ->(_) { User.current.admin? },
           caption: :"repositories.admin.menu",
           icon: :repo

      project_module(:repositories, dependencies: :work_package_tracking) do
        permission :show_repository_content, {}, permissible_on: %i[work_package project]
      end
    end

    # TODO: rename to repositories
    initializer "gitlab.resource_colors" do
      Rails.application.reloader.to_prepare do
        ::Highlighting::Registry.register_static(key: "gitlab_issue_status",
                                                 values: ::Repositories::IssueStatuses::AVAILABLE)
        ::Highlighting::Registry.register_static(key: "gitlab_merge_request_status",
                                                 values: ::Repositories::MergeRequestStatuses::AVAILABLE)
        ::Highlighting::Registry.register_static(key: "gitlab_pipeline_status",
                                                 values: ::Repositories::PipelineStatuses::AVAILABLE)
      end
    end

    initializer "repositories.register_gitlab_hook" do
      ::OpenProject::Webhooks.register_hook "gitlab" do |hook, environment, params, user|
        ::Repositories::Gitlab::HookHandler.new.process(hook, environment, params, user)
      end
    end

    initializer "repositories.subscribe_to_gitlab_notifications" do
      %w[merge_request note issue push pipeline].each do |event|
        ::OpenProject::Notifications.subscribe("gitlab.#{event}_hook") do |payload|
          ::Repositories::Gitlab::NotificationHandlers.public_send(:"#{event}_hook", payload)
        end
      end
    end

    extend_api_response(:v3, :work_packages, :work_package) do
      show_repositories = -> {
        Repositories::Provider.exists? &&
          current_user.allowed_in_work_package?(:show_repository_content, represented)
      }

      link :repositories, cache_if: show_repositories do
        next if represented.new_record?

        {
          href: "#{work_package_path(id: represented.id)}/tabs/repositories",
          title: "repositories" # TODO: localize?
        }
      end

      %i[repository_issues repository_merge_requests repository_branches repository_commits].each do |resource|
        link resource.to_s.camelize(:lower).to_sym, cache_if: show_repositories do
          next if represented.new_record?

          { href: api_v3_paths.public_send(:"#{resource}_by_work_package", represented.id) }
        end
      end
    end

    %i[repository_issue repository_merge_request repository_branch repository_commit].each do |resource|
      plural = resource.to_s.pluralize

      add_api_resource_paths resource, only: :show

      add_api_path :"#{plural}_by_work_package" do |work_package_id|
        "#{work_package(work_package_id)}/#{plural}"
      end
    end

    add_api_resource_paths :repository_pipeline, only: :show

    add_api_path :repository_pipelines_by_merge_request do |merge_request_id|
      "#{repository_merge_request(merge_request_id)}/repository_pipelines"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Repositories::Issues::IssuesAPI
      mount ::API::V3::Repositories::MergeRequests::MergeRequestsAPI
      mount ::API::V3::Repositories::Branches::BranchesAPI
      mount ::API::V3::Repositories::Commits::CommitsAPI
      mount ::API::V3::Repositories::Pipelines::PipelinesAPI
    end

    add_api_endpoint "API::V3::WorkPackages::WorkPackagesAPI", :id do
      mount ::API::V3::Repositories::Issues::IssuesByWorkPackageAPI
      mount ::API::V3::Repositories::MergeRequests::MergeRequestsByWorkPackageAPI
      mount ::API::V3::Repositories::Branches::BranchesByWorkPackageAPI
      mount ::API::V3::Repositories::Commits::CommitsByWorkPackageAPI
    end

    include_module "WorkPackages::Repositories", into: "WorkPackage"
  end
end

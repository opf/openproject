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

    extend_api_response(:v3, :work_packages, :work_package) do
      link :repositories,
            cache_if: -> {
              Repositories::Provider.exists? &&
                current_user.allowed_in_work_package?(:show_repository_content, represented)
            } do
        next if represented.new_record?

        {
          href: "#{work_package_path(id: represented.id)}/tabs/repositories",
          title: "repositories" # TODO: localize?
        }
      end
    end

    include_module "WorkPackages::Repositories", into: "WorkPackage"
  end
end

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  class JiraInstanceMetaDataJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      total_limit: 2,
      enqueue_limit: 1,
      perform_limit: 1,
      key: -> { "Import::JiraInstanceMetaDataJob-#{arguments.last}" }
    )

    def perform(jira_import_id)
      jira_import = Import::JiraImport.find(jira_import_id)
      get_meta(jira_import)
    end

    def get_meta(jira_import)
      jira = jira_import.jira
      @client = Import::JiraClient.new(url: jira.url, personal_access_token: jira.personal_access_token)
      available = collect_metadata
      jira_import.update!(job_id: nil, available:, error: nil)
      jira_import.transition_to!(:instance_meta_done)
    rescue StandardError => e
      jira_import&.transition_to!(:instance_meta_error, error: e.message, error_backtrace: e.backtrace)
      jira_import&.update!(job_id: nil, error: e.message)
    end

    def collect_metadata
      issue_types_count = @client.issue_types_count
      statuses_count = @client.statuses_count
      issues_count = @client.issues_count
      users_count = @client.applicationrole.inject(0) do |users_count, application|
        users_count + application["userCount"]
      end
      projects = collect_projects
      server_info = @client.server_info
      {
        "projects" => projects,
        "total_issues" => issues_count,
        "total_statuses" => statuses_count,
        "total_issue_types" => issue_types_count,
        "total_users" => users_count,
        "server_info" => server_info
      }
    end

    def collect_projects
      @client.projects.filter_map do |project|
        next unless project_browsable?(project["key"])

        { "id" => project["id"], "key" => project["key"], "name" => project["name"] }
      end
    end

    def project_browsable?(project_key)
      @client.issues(jql: "project = '#{project_key}'", max_results: 0, fields: "id")
      true
    rescue Import::JiraClient::ApiError => e
      if e.status == 400
        false
      else
        raise e
      end
    end
  end
end

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
  class JiraProjectsMetaDataJob < ApplicationJob
    include GoodJob::ActiveJobExtensions::Concurrency

    good_job_control_concurrency_with(
      total_limit: 2,
      enqueue_limit: 1,
      perform_limit: 1,
      key: -> { "Import::JiraProjectsMetaDataJob-#{arguments.last}" }
    )

    def perform(jira_import_id)
      jira_import = Import::JiraImport.find(jira_import_id)
      get_meta(jira_import)
    rescue StandardError => e
      jira_import&.transition_to!(:projects_meta_error, error: e.message, error_backtrace: e.backtrace)
      jira_import&.update!(job_id: nil, error: e.message)
    end

    def get_meta(jira_import)
      jira = jira_import.jira
      client = Import::JiraClient.new(url: jira.url, personal_access_token: jira.personal_access_token)
      selected = collect_metadata(client, jira_import.project_ids)
      jira_import.transition_to!(:projects_meta_done, selected:)
      jira_import.update!(job_id: nil, selected:, error: nil)
    end

    def collect_metadata(client, project_ids)
      issues_count = 0
      status_ids = []
      issue_type_ids = []

      project_ids.map do |project_id|
        project_issues_count, project_status_ids, project_issue_type_ids = collect_project_metadata(client, project_id)

        issue_type_ids = issue_type_ids.concat(project_issue_type_ids).uniq
        status_ids = status_ids.concat(project_status_ids).uniq
        issues_count += project_issues_count
      end

      {
        "issues_count" => issues_count,
        "status_ids" => status_ids,
        "issue_type_ids" => issue_type_ids
      }
    end

    def collect_project_metadata(client, project_id)
      project_statuses = client.project_statuses(project_id)
      project_issue_type_ids = project_statuses.pluck("id")
      project_status_ids = project_statuses.flat_map { |type| type["statuses"].map { |status| status["id"] } }

      result = client.issues(jql: "project = '#{project_id}'", max_results: 0)
      project_issues_count = result["total"]

      [project_issues_count, project_status_ids, project_issue_type_ids]
    end
  end
end

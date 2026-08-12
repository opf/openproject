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
  class JiraFetchProjectsJob < ApplicationJob
    include JiraFetchCustomFields

    def perform(jira_import_id)
      @jira_import = Import::JiraImport.find(jira_import_id)
      jira = @jira_import.jira
      @jira_id = jira.id
      @updated_at = Time.zone.now
      @created_at = @updated_at
      @jira_client = Import::JiraClient.new(url: jira.url, personal_access_token: jira.personal_access_token)

      sync_issue_types
      sync_priorities
      sync_statuses
      sync_projects
      sync_issues
      sync_custom_fields
    end

    private

    def sync_issue_types
      issue_types_upsert_data = @jira_client.issue_types.map do |issue_type|
        {
          payload: issue_type,
          jira_id: @jira_id,
          jira_issue_type_id: issue_type.fetch("id"),
          jira_import_id: @jira_import.id,
          created_at: @created_at,
          updated_at: @updated_at
        }
      end
      Import::JiraIssueType.upsert_all(issue_types_upsert_data, unique_by: %i[jira_id jira_issue_type_id])
    end

    def sync_priorities
      priorities_upsert_data = @jira_client.priorities.map do |priority|
        {
          payload: priority,
          jira_id: @jira_id,
          jira_priority_id: priority.fetch("id"),
          jira_import_id: @jira_import.id,
          created_at: @created_at,
          updated_at: @updated_at
        }
      end
      Import::JiraPriority.upsert_all(priorities_upsert_data, unique_by: %i[jira_id jira_priority_id])
    end

    def sync_statuses
      statuses_upsert_data = @jira_client.statuses.map do |status|
        {
          payload: status,
          jira_id: @jira_id,
          jira_status_id: status.fetch("id"),
          jira_import_id: @jira_import.id,
          created_at: @created_at,
          updated_at: @updated_at
        }
      end
      Import::JiraStatus.upsert_all(statuses_upsert_data, unique_by: %i[jira_id jira_status_id])
    end

    def sync_projects
      projects_upsert_data = @jira_client.projects.map do |p|
        {
          payload: p,
          jira_id: @jira_id,
          jira_project_id: p.fetch("id"),
          jira_import_id: @jira_import.id,
          created_at: @created_at,
          updated_at: @updated_at
        }
      end
      Import::JiraProject.upsert_all(projects_upsert_data, unique_by: %i[jira_id jira_project_id])
    end

    def sync_issues
      Import::JiraProject.where(jira_id: @jira_id, jira_project_id: @jira_import.project_ids).find_each do |jira_project|
        sync_project_issues(jira_project)
      end
    end

    def sync_project_issues(jira_project)
      jql = "project = '#{jira_project.payload['key']}'"
      start_at = 0
      loop do
        result = @jira_client.issues(jql:, start_at:, max_results: 5)
        issues = result["issues"]
        issues_upsert_data = issues.map do |issue|
          {
            payload: issue,
            jira_id: @jira_id,
            jira_project_id: jira_project.id,
            jira_issue_id: issue.fetch("id"),
            jira_import_id: @jira_import.id,
            created_at: @created_at,
            updated_at: @updated_at
          }
        end
        Import::JiraIssue.upsert_all(issues_upsert_data, unique_by: %i[jira_id jira_issue_id])
        start_at = result["startAt"] + result["maxResults"]
        break if start_at >= result["total"]
      end
    end
  end
end

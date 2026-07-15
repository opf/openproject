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
  class JiraFetchIssuesJob < JiraFetchBaseJob
    private

    def fetch_data
      Import::JiraProject.where(jira_id: @jira_id, jira_project_id: @jira_import.project_ids).find_each do |jira_project|
        sync_project_issues(jira_project)
      end
    end

    def sync_project_issues(jira_project)
      jql = "project = '#{jira_project.payload['key']}'"
      start_at = 0
      loop do
        result = @jira_client.issues(jql:, start_at:, max_results: 50)
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

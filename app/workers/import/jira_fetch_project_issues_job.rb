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
  class JiraFetchProjectIssuesJob < ProgressableJob
    include JiraJobUtils
    include Import::JiraImportLogging

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      "Fetch issues for project '#{jira_project_name}'"
    end

    def percentage
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        cursor["start_at"] * 100 / cursor["total"]
      else
        0
      end
    end

    # rubocop:disable Metrics/AbcSize
    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      with_jira_log_tags(jira_import_id:, jira_project_id:, jira_object_type: :project) do
        Rails.logger.info "Fetching issues started"
      end

      prepare_jira_import_ivars(jira_import_id)
      jira_project = Import::JiraProject.find(jira_project_id)
      jira_project_key = jira_project.payload["key"]

      cursor ||= @jira_import.get_job_cursor(self)
      start_at = cursor&.dig("start_at") || 0

      Enumerator.new do |yielder|
        loop do
          jql = "project = '#{jira_project_key}' ORDER BY id ASC"
          response = @jira_client.issues(jql:, start_at:, max_results: 50)

          issues = response["issues"]
          total  = response["total"]

          break if issues.empty?

          new_cursor = { "start_at" => start_at, "total" => total }
          issues_and_total = { "issues" => issues, "total" => total }

          @jira_import.set_job_cursor(self, new_cursor)

          # This loop body runs later, inside the Enumerator's own Fiber, once build_enumerator
          # has already returned and the with_jira_log_tags call above has already closed - so
          # it needs its own full set of tags rather than nesting inside (and inheriting from)
          # that one.
          with_jira_log_tags(jira_import_id:, jira_project_id:, jira_object_type: :project,
                             jira_object_id_or_name: jira_project_key) do
            Rails.logger.info "Fetched #{start_at + issues.size} of #{total} issues"
          end

          yielder.yield(
            issues_and_total,
            new_cursor
          )

          start_at += issues.size
        end
      end
    end

    def each_iteration(issues_and_total, jira_import_id, jira_project_id)
      issues = issues_and_total["issues"]
      issues_upsert_data = issues.map do |payload|
        with_jira_log_tags(jira_import_id:, jira_project_id:, jira_issue_key: payload["key"],
                           jira_object_type: :issue, jira_object_id_or_name: payload["key"]) do
          Rails.logger.debug "Fetched issue"
        end
        {
          payload:,
          jira_project_id:,
          origin_id: payload.fetch("id"),
          jira_import_id:,
          created_at: @created_at,
          updated_at: @updated_at
        }
      end
      Import::JiraIssue.upsert_all(issues_upsert_data, unique_by: %i[jira_import_id origin_id])
    end
    # rubocop:enable Metrics/AbcSize
  end
end

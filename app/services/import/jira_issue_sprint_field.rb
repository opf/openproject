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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Import
  class JiraIssueSprintField
    def self.from_client(jira_client)
      new(jira_client.fields
            .select { |field| field.dig("schema", "custom") == Import::JiraSprintValueParser::SPRINT_FIELD_SCHEMA }
            .pluck("id"))
    end

    def self.from_staged_fields(jira_import)
      new(Import::JiraField.where(jira_import:)
            .where("payload #>> '{schema,custom}' = ?", Import::JiraSprintValueParser::SPRINT_FIELD_SCHEMA)
            .pluck(:origin_id))
    end

    def initialize(keys)
      @keys = keys
    end

    def each_issue_sprint_ids(issues)
      return if @keys.empty?

      issues.pluck(:jira_project_id, *@keys.map { field_value(it) }).each do |jira_project_id, *values|
        sprint_ids = values.flat_map { Import::JiraSprintValueParser.sprint_ids(it) }.uniq
        yield jira_project_id, sprint_ids if sprint_ids.any?
      end
    end

    def current_sprint_id(jira_issue)
      values = @keys.flat_map { |key| Array.wrap(jira_issue.payload.dig("fields", key)) }
      Import::JiraSprintValueParser.current_sprint_id(values)
    end

    def sprint_ids(issues)
      ids = []
      each_issue_sprint_ids(issues) { |_jira_project_id, sprint_ids| ids.concat(sprint_ids) }
      ids.uniq
    end

    private

    def field_value(key)
      Arel.sql(Import::JiraIssue.sanitize_sql(["jira_issues.payload -> 'fields' -> ?", key]))
    end
  end
end

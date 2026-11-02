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
  class JiraCreateParentChildRelationsFromSubtasksJob < ProgressableJob
    include Import::JiraJobUtils

    on_complete do
      tagged_log("jira_import_id:#{arguments[0]}",
                 "jira_project_id:#{jira_project_key(arguments[1])}",
                 "jira_object_type:project") do
        Rails.logger.debug "Creating parent-child relations finished"
      end
    end

    def text
      jira_project_name = Import::JiraProject.find(arguments[1]).payload["name"]
      I18n.t(:"admin.jira.run.jobs.#{self.class.to_s.demodulize}.title", jira_project_name:)
    end

    # rubocop:disable-next Metrics/AbcSize
    def progress
      jira_import = Import::JiraImport.find(arguments[0])
      cursor = jira_import.get_job_cursor(self)
      if cursor.present?
        subtasks = subtasks_scope(jira_import.id, arguments[1])
        total = subtasks.count
        current = subtasks.where(id: ..cursor).count
        percentage = total.zero? ? 100.0 : (current.to_f / total * 100).round(2)
        { current:, total:, percentage: }
      else
        { current: 0, total: 0, percentage: 0 }
      end
    end

    def build_enumerator(jira_import_id, jira_project_id, cursor:)
      jira_project = jira_project(jira_project_id)
      tagged_log("jira_import_id:#{jira_import_id}",
                 "jira_project_id:#{jira_project.payload['key']}", "jira_object_type:project") do
        Rails.logger.debug "Creating parent-child relations started"
        @jira_import = Import::JiraImport.find(jira_import_id)

        cursor ||= @jira_import.get_job_cursor(self)
        enumerator_builder.active_record_on_records(
          subtasks_scope(jira_import_id, jira_project_id),
          cursor:
        )
      end
    end

    def each_iteration(jira_issue, jira_import_id, jira_project_id)
      jira_issue_key = jira_issue.payload["key"]
      tagged_log("jira_import_id:#{jira_import_id}",
                 "jira_project_id:#{jira_project_key(jira_project_id)}",
                 "jira_issue_key:#{jira_issue_key}") do
        Journal::NotificationConfiguration.with(false) do
          Journal::EventConfiguration.with(false) do
            ActiveRecord::Base.transaction do
              set_parent_child_relation(jira_issue)
              @jira_import.set_job_cursor(self, jira_issue.id)
            end
          end
        end
      end
    end

    private

    # rubocop:disable-next Metrics/AbcSize, Metrics/PerceivedComplexity
    def set_parent_child_relation(jira_issue)
      parent_data = jira_issue.payload.dig("fields", "parent")
      return if parent_data.blank?

      parent_jira_id = parent_data["id"]
      return if parent_jira_id.blank?

      parent_jira_issue = Import::JiraIssue.find_by(
        jira_import: @jira_import,
        origin_id: parent_jira_id
      )

      if parent_jira_issue.nil?
        Rails.logger.warn "Parent Jira issue #{parent_jira_id} not found for subtask #{jira_issue.origin_id}"
        return
      end

      child_wp = @jira_import.find_op_leg(jira_issue)
      parent_wp = @jira_import.find_op_leg(parent_jira_issue)

      if child_wp.nil? || parent_wp.nil?
        Rails.logger.warn "Work packages not found for hierarchy: child=#{child_wp&.id}, parent=#{parent_wp&.id}"
        return
      end

      Rails.logger.debug { "Setting parent of #{child_wp.id} to #{parent_wp.id}" }
      call = WorkPackages::UpdateService
               .new(user: User.system, model: child_wp, contract_class: EmptyContract)
               .with_state(bulk_duplicate_in_progress: true)
               .call(parent_id: parent_wp.id)

      return if call.success?

      Rails.logger.error "Failed to set parent for work package #{child_wp.id}: #{call.message}"
      raise call.message
    end

    def subtasks_scope(jira_import_id, jira_project_id)
      Import::JiraIssue
        .where(jira_import_id:, jira_project_id:)
        .where("payload -> 'fields' -> 'parent' IS NOT NULL")
        .where("payload -> 'fields' -> 'parent' != 'null'::jsonb")
    end
  end
end

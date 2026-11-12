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
  class JiraCreateRelationsJob < ProgressableJob
    include Import::JiraJobUtils

    JIRA_TO_OP_RELATIONS_MAPPING = {
      "Blocks" => Relation::TYPE_BLOCKS,
      "Duplicate" => Relation::TYPE_DUPLICATES
    }.freeze

    on_complete do
      tagged_log("jira_import_id:#{arguments[0]}",
                 "jira_project_id:#{jira_project_key(arguments[1])}",
                 "jira_object_type:project") do
        Rails.logger.debug "Creating relations finished"
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
        issues = issues_with_links_scope(jira_import.id, arguments[1])
        total = issues.count
        current = issues.where(id: ..cursor).count
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
        Rails.logger.debug "Creating relations started"
        @jira_import = Import::JiraImport.find(jira_import_id)

        cursor ||= @jira_import.get_job_cursor(self)
        enumerator_builder.active_record_on_records(
          issues_with_links_scope(jira_import_id, jira_project_id),
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
              process_issue_links(jira_issue)
              @jira_import.set_job_cursor(self, jira_issue.id)
            end
          end
        end
      end
    end

    private

    def process_issue_links(jira_issue)
      issue_links = jira_issue.payload.dig("fields", "issuelinks") || []
      current_wp = @jira_import.find_op_leg(jira_issue)

      return if current_wp.nil?

      issue_links.each { |link| process_link(link, current_wp) }
    end

    def process_link(link, current_wp)
      jira_link_type = link["type"]
      from_wp, to_wp = resolve_link_direction(link, current_wp)

      return log_missing_work_package(link) if to_wp.nil? || from_wp.nil?
      return log_self_referential(from_wp) if from_wp.id == to_wp.id

      create_relation(
        from_wp,
        to_wp,
        relation_type: JIRA_TO_OP_RELATIONS_MAPPING.fetch(jira_link_type["name"], Relation::TYPE_RELATES),
        description: build_description(jira_link_type, from_wp, to_wp)
      )
    end

    def log_missing_work_package(link)
      linked_issue_data = link["outwardIssue"] || link["inwardIssue"]
      linked_key = linked_issue_data&.dig("key") || linked_issue_data&.dig("id")
      Rails.logger.warn "Cannot create relation: target work package not found for Jira issue #{linked_key}"
    end

    def log_self_referential(work_package)
      Rails.logger.warn "Skipping self-referential relation for work package #{work_package.id}"
    end

    def resolve_link_direction(link, current_wp)
      if link["outwardIssue"]
        # Current issue -> linked issue (e.g., "DPPP-6 blocks ZBA2-1")
        linked_wp = find_linked_work_package(link["outwardIssue"])
        [current_wp, linked_wp]
      else
        # Linked issue -> current issue (e.g., "KIWNEU1-1 tests DPPP-6")
        linked_wp = find_linked_work_package(link["inwardIssue"])
        [linked_wp, current_wp]
      end
    end

    def find_linked_work_package(linked_issue_data)
      return nil if linked_issue_data.blank?

      linked_jira_id = linked_issue_data["id"]

      # First, try to find in current import's JiraIssue records
      jira_issue = Import::JiraIssue.find_by(
        jira_import: @jira_import,
        origin_id: linked_jira_id
      )

      if jira_issue
        return @jira_import.find_op_leg(jira_issue)
      end

      # If not in current import, check persistent mapping (origin columns)
      # The linked issue might have been imported in a previous run
      WorkPackage.find_by(
        origin_source: "jira_data_center",
        origin_id: linked_jira_id,
        origin_host: @jira_import.jira.url
      )
    end

    def build_description(jira_link_type, from_wp, to_wp)
      return nil if JIRA_TO_OP_RELATIONS_MAPPING.key?(jira_link_type["name"])

      # Format: "TO-ID is tested by FROM-ID" (using the inward label from Jira)
      "#{to_wp.formatted_id} #{jira_link_type['inward']} #{from_wp.formatted_id}"
    end

    def create_relation(from_wp, to_wp, relation_type:, description:)
      if relation_exists?(from_wp, to_wp)
        Rails.logger.warn { "Relation already exists between #{from_wp.id} and #{to_wp.id}" }
        return
      end

      call = Relations::CreateService.new(user: User.system).call(
        from: from_wp, to: to_wp, relation_type:, description:
      )

      Rails.logger.error "Failed to create relation: #{call.message}" unless call.success?
    end

    def relation_exists?(from_wp, to_wp)
      # OpenProject allows only one relation between any two work packages.
      # Check both directions since (A→B) and (B→A) are considered the same pair.
      Relation.where(from_id: from_wp.id, to_id: to_wp.id)
              .or(Relation.where(from_id: to_wp.id, to_id: from_wp.id))
              .exists?
    end

    def issues_with_links_scope(jira_import_id, jira_project_id)
      Import::JiraIssue
        .where(jira_import_id:, jira_project_id:)
        .where("jsonb_array_length(payload -> 'fields' -> 'issuelinks') > 0")
    end
  end
end

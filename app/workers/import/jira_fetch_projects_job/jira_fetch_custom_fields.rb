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

module Import
  class JiraFetchProjectsJob
    module JiraFetchCustomFields
      # Jira custom-field types that carry per-context "Field context" allowedValues and therefore
      # require editmeta resolution to capture project-specific option lists.
      OPTION_BASED_CUSTOM_SUFFIXES = %w[select multiselect multicheckboxes radiobuttons cascadingselect].freeze

      def sync_custom_fields
        used_custom_field_ids = collect_used_custom_field_ids
        return unless used_custom_field_ids.any?

        upsert_custom_fields(used_custom_field_ids)
        sync_custom_field_options
      end

      def collect_used_custom_field_ids
        used_ids = Set.new
        Import::JiraProject.where(jira_id: @jira_id, jira_project_id: @jira_import.project_ids).find_each do |jira_project|
          Import::JiraIssue.where(jira_id: @jira_id, jira_project_id: jira_project.id).find_each do |issue|
            issue.payload["fields"].each do |key, value|
              used_ids << key if key.start_with?("customfield_") && value.present?
            end
          end
        end
        used_ids
      end

      def upsert_custom_fields(used_custom_field_ids)
        used_fields = @jira_client.fields.select do |field|
          field.fetch("custom", false) && used_custom_field_ids.include?(field.fetch("id"))
        end
        fields_upsert_data = used_fields.map do |field|
          {
            payload: field,
            jira_id: @jira_id,
            jira_field_id: field.fetch("id"),
            jira_import_id: @jira_import.id,
            created_at: @created_at,
            updated_at: @updated_at
          }
        end
        Import::JiraField.upsert_all(fields_upsert_data, unique_by: %i[jira_id jira_field_id]) if fields_upsert_data.any?
      end

      # For every list-type JiraField, populates `contextGroups` on its payload describing the
      # distinct Jira "Field Context" option sets used by imported issues:
      #
      #   "contextGroups": [
      #     {
      #       "projects":      ["DYX", "ABC"],   # Jira project keys sharing this option set
      #       "issuetypes":    ["10100"],        # Jira issue type ids sharing this option set
      #       "allowedValues": [{ "value" => "Low" }, ...]
      #     },
      #     ...
      #   ]
      #
      # In Jira DC, custom-field lists can be overridden per project and per issue type via
      # Field Contexts; there is no officially supported public API to enumerate those contexts
      # or fetch options across them. We derive them by calling /rest/api/2/issue/{key}/editmeta
      # once per distinct (project, issuetype) pair appearing in the imported issues - editmeta
      # returns the allowed values for that issue's current context. Identical option sets are
      # merged into a single group so the import job can later materialize one OP custom field
      # per distinct group.
      def sync_custom_field_options
        option_based_fields_by_jira_id = Import::JiraField
                                           .where(jira_id: @jira_id, jira_import_id: @jira_import.id)
                                           .select { |f| option_based_field?(f) }
                                           .index_by(&:jira_field_id)
        return if option_based_fields_by_jira_id.empty?

        collect_field_contexts_via_editmeta(option_based_fields_by_jira_id)
      end

      def collect_field_contexts_via_editmeta(option_based_fields_by_jira_id)
        groups_by_field = Hash.new { |h, k| h[k] = {} }
        each_sample_issue_per_project_issuetype do |jira_issue|
          record_editmeta_contexts_for_issue(jira_issue, option_based_fields_by_jira_id, groups_by_field)
        end
        persist_context_groups(groups_by_field, option_based_fields_by_jira_id)
      end

      def each_sample_issue_per_project_issuetype
        seen = Set.new
        project_ids = Import::JiraProject
                        .where(jira_id: @jira_id, jira_project_id: @jira_import.project_ids)
                        .pluck(:id)
        Import::JiraIssue.where(jira_id: @jira_id, jira_project_id: project_ids).find_each do |jira_issue|
          key = issue_context_key(jira_issue)
          next if seen.include?(key)

          seen << key
          yield jira_issue
        end
      end

      def issue_context_key(jira_issue)
        [
          jira_issue.payload.dig("fields", "project", "key"),
          jira_issue.payload.dig("fields", "issuetype", "id")
        ]
      end

      def record_editmeta_contexts_for_issue(jira_issue, option_based_fields_by_jira_id, groups_by_field)
        issue_key = jira_issue.payload["key"] || jira_issue.jira_issue_id
        project_key, issuetype_id = issue_context_key(jira_issue)
        result = @jira_client.issue_editmeta(issue_key)
        record_editmeta_fields(result["fields"], project_key, issuetype_id, option_based_fields_by_jira_id, groups_by_field)
      rescue Import::JiraClient::ApiError => e
        Rails.logger.warn("Could not fetch editmeta for issue #{issue_key}: #{e.message}.")
      end

      def record_editmeta_fields(fields_meta, project_key, issuetype_id, option_based_fields_by_jira_id, groups_by_field)
        (fields_meta || {}).each do |field_key, field_meta|
          next unless option_based_fields_by_jira_id.key?(field_key)
          next if field_meta["allowedValues"].blank?

          record_context(groups_by_field[field_key], field_meta["allowedValues"], project_key, issuetype_id)
        end
      end

      def record_context(field_groups, allowed_values, project_key, issuetype_id)
        signature = context_signature(allowed_values)
        bucket = field_groups[signature] ||= {
          "projects" => Set.new,
          "issuetypes" => Set.new,
          "allowedValues" => allowed_values
        }
        bucket["projects"] << project_key if project_key
        bucket["issuetypes"] << issuetype_id if issuetype_id
      end

      # Produces a signature that uniquely identifies an allowed-values set.
      # For flat options (select / multiselect) this is just the sorted parent values.
      # For cascading selects the children are included so that two contexts sharing
      # the same parents but different children are kept separate.
      def context_signature(allowed_values)
        allowed_values.map do |av|
          children = Array(av["children"]).pluck("value").compact.sort
          children.any? ? "#{av['value']}:#{children.join(',')}" : av["value"]
        end.sort
      end

      def persist_context_groups(groups_by_field, option_based_fields_by_jira_id)
        groups_by_field.each do |jira_field_id, groups|
          jira_field = option_based_fields_by_jira_id[jira_field_id]
          context_groups = groups.values.map do |g|
            {
              "projects" => g["projects"].to_a.sort,
              "issuetypes" => g["issuetypes"].to_a.sort,
              "allowedValues" => g["allowedValues"]
            }
          end
          jira_field.update!(payload: jira_field.payload.merge("contextGroups" => context_groups))
        end
      end

      def option_based_field?(jira_field)
        schema = jira_field.payload["schema"] || {}
        custom_suffix = schema["custom"].to_s.split(":").last
        return true if OPTION_BASED_CUSTOM_SUFFIXES.include?(custom_suffix)

        # Fallback: catch option-typed fields from third-party plugins whose
        # custom suffix is not in the list above.
        type = schema["type"]
        %w[option option-with-child].include?(type) || (type == "array" && schema["items"] == "option")
      end
    end
  end
end

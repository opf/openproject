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
  class JiraFetchCustomFieldJob < ApplicationJob
    include Import::JiraJobUtils

    # Jira custom-field types that carry per-context "Field context" allowedValues and therefore
    # require editmeta resolution to capture project-specific option lists.
    OPTION_BASED_CUSTOM_SUFFIXES = %w[select multiselect multicheckboxes radiobuttons cascadingselect].freeze

    def text
      "Fetch Custom Fields"
    end

    def perform(jira_import_id)
      prepare_jira_import_ivars(jira_import_id)

      used_custom_field_ids = collect_used_custom_field_ids
      return unless used_custom_field_ids.any?

      upsert_custom_fields(used_custom_field_ids)
      sync_custom_field_options
    end

    private

    def collect_used_custom_field_ids
      used_ids = Set.new
      Import::JiraProject.where(jira_import_id: @jira_import.id, origin_id: @jira_import.project_ids).find_each do |jira_project|
        Import::JiraIssue.where(jira_import_id: @jira_import.id, jira_project_id: jira_project.id).find_each do |issue|
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
      fields_upsert_data = used_fields.map do |payload|
        {
          payload:,
          origin_id: payload.fetch("id"),
          jira_import_id: @jira_import.id,
          created_at: @created_at,
          updated_at: @updated_at
        }
      end
      Import::JiraField.upsert_all(fields_upsert_data, unique_by: %i[jira_import_id origin_id]) if fields_upsert_data.any?
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
    # Field Contexts. Identical option sets are merged into a single group so the import job can
    # later materialize one OP custom field per distinct group.
    def sync_custom_field_options
      option_based_fields_by_jira_id = Import::JiraField
                                         .where(jira_import_id: @jira_import.id)
                                         .select { |f| option_based_field?(f) }
                                         .index_by(&:origin_id)
      return if option_based_fields_by_jira_id.empty?

      collect_field_contexts_via_options_api(option_based_fields_by_jira_id)
    rescue Import::JiraClient::UnsupportedEndpointError => e
      Rails.logger.info("Jira custom field options endpoint unusable (#{e.message}), falling back to editmeta.")
      collect_field_contexts_via_editmeta(option_based_fields_by_jira_id)
    end

    # Jira DC >= 9.3 reports a custom field's options per Field Context directly. Compared to the
    # editmeta route below this asks only for the fields the import actually needs instead of the
    # metadata of every field on an edit screen, and it also covers fields that sit on no edit
    # screen at all. Raises UnsupportedEndpointError if the endpoint never answered, so that the
    # caller can fall back before anything has been persisted.
    def collect_field_contexts_via_options_api(option_based_fields_by_jira_id)
      @options_api_confirmed = false
      groups_by_field = Hash.new { |h, k| h[k] = {} }
      field_scopes_from_issues(option_based_fields_by_jira_id.keys).each do |field_key, scopes|
        jira_field = option_based_fields_by_jira_id.fetch(field_key)
        context_allowed_values(jira_field, scopes).each do |allowed_values, project_key, issuetype_id|
          record_context(groups_by_field[field_key], allowed_values, project_key, issuetype_id)
        end
      end
      persist_context_groups(groups_by_field, option_based_fields_by_jira_id)
    end

    def context_allowed_values(jira_field, scopes)
      scopes.filter_map do |project_key, project_id, issuetype_id|
        allowed_values = fetch_context_allowed_values(jira_field, project_id, issuetype_id)
        [allowed_values, project_key, issuetype_id] if allowed_values.present?
      end
    end

    def field_scopes_from_issues(field_keys)
      wanted = field_keys.to_set
      scopes = Hash.new { |h, k| h[k] = Set.new }
      import_issues.find_each { |issue| record_issue_field_scopes(issue, wanted, scopes) }
      scopes
    end

    def record_issue_field_scopes(issue, wanted_field_keys, scopes)
      scope = issue_context_scope(issue)
      issue.payload["fields"].each do |field_key, value|
        scopes[field_key] << scope if wanted_field_keys.include?(field_key) && value.present?
      end
    end

    def fetch_context_allowed_values(jira_field, project_id, issuetype_id)
      custom_field_id = custom_field_numeric_id(jira_field)
      return if custom_field_id.blank?

      options = @jira_client.custom_field_options(custom_field_id,
                                                  project_ids: [project_id].compact,
                                                  issue_type_ids: [issuetype_id].compact)
      @options_api_confirmed = true
      nested_allowed_values(options)
    rescue Import::JiraClient::UnsupportedEndpointError, Import::JiraClient::ApiError => e
      raise Import::JiraClient::UnsupportedEndpointError, e.message unless @options_api_confirmed

      Rails.logger.warn("Could not fetch options of custom field #{jira_field.origin_id}: #{e.message}.")
      nil
    end

    def custom_field_numeric_id(jira_field)
      jira_field.payload.dig("schema", "customId") || jira_field.origin_id.to_s[/\d+/]
    end

    # Rebuilds the nested allowedValues structure of a context group from the flat option list the
    # options endpoint returns, where a cascading select expresses its tree through "childrenIds".
    # Disabled options are left out to match what editmeta reports; values that imported issues
    # still hold are recovered from the issues themselves during custom field creation.
    def nested_allowed_values(options)
      options_by_id = options.index_by { |option| option["id"].to_s }
      seen = Set.new
      root_options(options).filter_map { |option| allowed_value_tree(option, options_by_id, seen) }
    end

    def root_options(options)
      child_ids = options.flat_map { |option| Array(option["childrenIds"]).map(&:to_s) }.to_set
      options.reject { |option| child_ids.include?(option["id"].to_s) }
    end

    def allowed_value_tree(option, options_by_id, seen)
      return if option["disabled"]
      return unless seen.add?(option["id"].to_s)

      allowed_value = { "id" => option["id"].to_s, "value" => option["value"] }
      children = child_allowed_values(option, options_by_id, seen)
      allowed_value["children"] = children if children.any?
      allowed_value
    end

    def child_allowed_values(option, options_by_id, seen)
      Array(option["childrenIds"])
        .filter_map { |child_id| options_by_id[child_id.to_s] }
        .filter_map { |child| allowed_value_tree(child, options_by_id, seen) }
    end

    # Fallback for Jira DC < 9.3, which has no endpoint enumerating a field's contexts or their
    # options. It derives them by calling /rest/api/2/issue/{key}/editmeta once per distinct
    # (project, issuetype) pair appearing in the imported issues - editmeta returns the allowed
    # values for that issue's current context, so a field on no edit screen stays invisible here.
    def collect_field_contexts_via_editmeta(option_based_fields_by_jira_id)
      groups_by_field = Hash.new { |h, k| h[k] = {} }
      each_sample_issue_per_project_issuetype do |jira_issue|
        record_editmeta_contexts_for_issue(jira_issue, option_based_fields_by_jira_id, groups_by_field)
      end
      persist_context_groups(groups_by_field, option_based_fields_by_jira_id)
    end

    def import_project_ids
      @import_project_ids ||= Import::JiraProject
                                .where(jira_import_id: @jira_import.id, origin_id: @jira_import.project_ids)
                                .pluck(:id)
    end

    def import_issues
      Import::JiraIssue.where(jira_import_id: @jira_import.id, jira_project_id: import_project_ids)
    end

    def each_sample_issue_per_project_issuetype
      seen = Set.new
      import_issues.find_each do |jira_issue|
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

    def issue_context_scope(jira_issue)
      [
        jira_issue.payload.dig("fields", "project", "key"),
        jira_issue.payload.dig("fields", "project", "id"),
        jira_issue.payload.dig("fields", "issuetype", "id")
      ]
    end

    def record_editmeta_contexts_for_issue(jira_issue, option_based_fields_by_jira_id, groups_by_field)
      issue_key = jira_issue.payload["key"] || jira_issue.origin_id
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

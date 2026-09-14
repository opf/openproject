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

    OPTION_BASED_CUSTOM_SUFFIXES = %w[select multiselect multicheckboxes radiobuttons cascadingselect].freeze

    def text
      "Fetch Custom Fields"
    end

    def perform(jira_import_id)
      prepare_jira_import_ivars(jira_import_id)

      @index = Import::JiraCustomField::IssueValueIndex.scan(@jira_import)
      return if @index[:used_keys].empty?

      upsert_custom_fields(@index[:used_keys])
      sync_custom_field_options
      store_issue_value_index
    end

    private

    def store_issue_value_index
      stored = Import::JiraCustomField::IssueValueIndex.serialize(@index)
      Import::JiraField.transaction do
        Import::JiraField
          .where(jira_import_id: @jira_import.id).where.not(origin_id: stored.keys)
          .update_all(issue_values: { "used" => false })
        stored.each do |origin_id, issue_values|
          Import::JiraField.where(jira_import_id: @jira_import.id, origin_id:).update_all(issue_values:)
        end
      end
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

    def sync_custom_field_options
      option_based_fields_by_jira_id = Import::JiraField
                                         .where(jira_import_id: @jira_import.id)
                                         .select { |f| option_based_field?(f) }
                                         .index_by(&:origin_id)
      return if option_based_fields_by_jira_id.empty?

      collect_field_contexts_via_options_api(option_based_fields_by_jira_id)
    rescue Import::JiraClient::UnsupportedEndpointError => e
      Rails.logger.warn("Jira custom field options endpoint unusable (#{e.message}), falling back to editmeta. " \
                        "Option sets are then limited to what the issues' edit screens report.")
      collect_field_contexts_via_editmeta(option_based_fields_by_jira_id)
    end

    # Jira DC >= 9.3 reports a custom field's options per Field Context directly. Compared to the
    # editmeta route below this asks only for the fields the import actually needs instead of the
    # metadata of every field on an edit screen, and it also covers fields that sit on no edit
    # screen at all.
    def collect_field_contexts_via_options_api(option_based_fields_by_jira_id)
      @options_api_confirmed = false
      groups_by_field = Hash.new { |h, k| h[k] = {} }
      @index[:scopes].each do |field_key, scopes|
        jira_field = option_based_fields_by_jira_id[field_key]
        next if jira_field.nil?

        context_allowed_values(jira_field, scopes).each do |allowed_values, project_key, issuetype_id|
          record_context(groups_by_field[field_key], allowed_values, project_key, issuetype_id)
        end
      end
      persist_context_groups(groups_by_field, option_based_fields_by_jira_id)
    end

    def context_allowed_values(jira_field, scopes)
      scopes.filter_map do |project_key, jira_project_id, issuetype_id|
        allowed_values = fetch_context_allowed_values(jira_field, jira_project_origin_ids[jira_project_id], issuetype_id)
        [allowed_values, project_key, issuetype_id] if allowed_values.present?
      end
    end

    def jira_project_origin_ids
      @jira_project_origin_ids ||= Import::JiraProject.where(jira_import_id: @jira_import.id).pluck(:id, :origin_id).to_h
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
      raise unless @options_api_confirmed

      Rails.logger.warn("Could not fetch options of custom field #{jira_field.origin_id}: #{e.message}.")
      nil
    end

    def custom_field_numeric_id(jira_field)
      jira_field.payload.dig("schema", "customId") || jira_field.origin_id.to_s[/\d+/]
    end

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

    def collect_field_contexts_via_editmeta(option_based_fields_by_jira_id)
      groups_by_field = Hash.new { |h, k| h[k] = {} }
      Import::JiraCustomField::IssueValueIndex.sample_issue_keys(@jira_import).each do |scope, issue_key|
        record_editmeta_contexts(issue_key, *scope, option_based_fields_by_jira_id, groups_by_field)
      end
      persist_context_groups(groups_by_field, option_based_fields_by_jira_id)
    end

    def record_editmeta_contexts(issue_key, project_key, issuetype_id, option_based_fields_by_jira_id, groups_by_field)
      result = @jira_client.issue_editmeta(issue_key)
      record_editmeta_fields(result["fields"], project_key, issuetype_id, option_based_fields_by_jira_id, groups_by_field)
    rescue Import::JiraClient::ApiError => e
      Rails.logger.warn("Could not fetch editmeta for issue #{issue_key}: #{e.message}.")
    end

    def record_editmeta_fields(fields_meta, project_key, issuetype_id, option_based_fields_by_jira_id, groups_by_field)
      (fields_meta || {}).each do |field_key, field_meta|
        next unless option_based_fields_by_jira_id.key?(field_key)
        next if field_meta["allowedValues"].blank?
        next unless used_field_scopes.include?([field_key, project_key, issuetype_id])

        record_context(groups_by_field[field_key], field_meta["allowedValues"], project_key, issuetype_id)
      end
    end

    def used_field_scopes
      @used_field_scopes ||= @index[:scopes].flat_map do |field_key, scopes|
        scopes.map { |project_key, _jira_project_id, issuetype_id| [field_key, project_key, issuetype_id] }
      end.to_set
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

    def context_signature(allowed_values)
      JiraCustomField::ContextSignature.of(allowed_values)
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

      # fallback: catch option-typed fields from third-party plugins whose custom suffix is not in the list above.
      type = schema["type"]
      %w[option option-with-child].include?(type) || (type == "array" && schema["items"] == "option")
    end
  end
end

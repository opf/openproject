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
  class JiraCreateProjectJob
    module JiraImportCustomFields
      JIRA_IMPORT_GROUP_KEY = "Jira import"

      def collect_custom_field_attributes(custom_field_registry, jira_issue)
        custom_field_registry.each_with_object({}) do |entry, attrs|
          field_key = entry[:jira_field].origin_id
          raw_value = jira_issue.payload["fields"][field_key]
          next if raw_value.blank?

          context = find_context_for_issue(entry, jira_issue)
          next unless context

          custom_field = context[:custom_field]
          attrs[custom_field.attribute_getter] = context[:builder].convert_value(raw_value, custom_field)
        end
      end

      def custom_fields_for_issue(custom_field_registry, jira_issue)
        custom_field_registry.filter_map do |entry|
          raw_value = jira_issue.payload["fields"][entry[:jira_field].origin_id]
          next if raw_value.blank?

          find_context_for_issue(entry, jira_issue)&.dig(:custom_field)
        end.uniq
      end

      # Builds one OP custom field per (Jira field, context group) combination, before any
      # per-project import begins. Context groups describe which (project_key, issuetype_id)
      # tuples share an allowedValues set.
      def build_custom_field_registry
        jira_field_ids = collect_used_jira_field_ids
        return [] if jira_field_ids.empty?

        Import::JiraField
          .where(jira_import_id: @jira_import.id, origin_id: jira_field_ids)
          .flat_map { |jira_field| build_registry_entries_for_field(jira_field) }
      end

      def collect_used_jira_field_ids
        issue_field_values_index[:used_keys].to_a
      end

      def build_registry_entries_for_field(jira_field)
        return [] unless JiraImportCustomFieldBuilder.supported?(jira_field)

        if multicheckbox_field?(jira_field)
          build_multicheckbox_registry_entries(jira_field)
        elsif string_array_field?(jira_field)
          build_string_array_registry_entries(jira_field)
        else
          [{ jira_field:, contexts: build_contexts_for_field(jira_field) }]
        end
      end

      def multicheckbox_field?(jira_field)
        schema = jira_field.payload["schema"] || {}
        schema["custom"].to_s.end_with?(":multicheckboxes")
      end

      def string_array_field?(jira_field)
        schema = jira_field.payload["schema"] || {}
        schema["type"] == "array" && schema["items"] == "string"
      end

      def option_field?(jira_field)
        schema = jira_field.payload["schema"] || {}
        %w[option option-with-child].include?(schema["type"]) ||
          (schema["type"] == "array" && schema["items"] == "option")
      end

      def build_string_array_registry_entries(jira_field)
        allowed_values = Array(jira_field.payload["contextGroups"]).flat_map { |group| Array(group["allowedValues"]) }
        allowed_values = issue_string_values(jira_field).reduce(allowed_values) do |values, string_value|
          merge_allowed_value(values, { "value" => string_value })
        end
        contexts = [
          build_context_entry(jira_field, { "projects" => [], "issuetypes" => [], "allowedValues" => allowed_values })
        ]
        [{ jira_field:, contexts: }]
      end

      def build_multicheckbox_registry_entries(jira_field)
        groups = augmented_context_groups(jira_field)
        return [] if groups.blank?

        build_multicheckbox_entries_with_context_groups(jira_field, groups)
      end

      def build_multicheckbox_entries_with_context_groups(jira_field, groups)
        boolean_groups, list_groups = partition_multicheckbox_groups_by_value_count(groups)

        build_boolean_registry_entries(jira_field, boolean_groups) + build_list_registry_entries(jira_field, list_groups)
      end

      def partition_multicheckbox_groups_by_value_count(groups)
        boolean_groups = []
        list_groups = []

        groups.each do |group|
          option_values = option_labels(group["allowedValues"])
          if option_values.size == 1
            boolean_groups << { group:, option_value: option_values.first }
          elsif option_values.size > 1
            list_groups << group
          end
        end

        [boolean_groups, list_groups]
      end

      def build_boolean_registry_entries(jira_field, boolean_groups)
        grouped_by_value = boolean_groups.group_by { |bg| bg[:option_value] }
        needs_disambiguation = grouped_by_value.size > 1

        grouped_by_value.map do |option_value, grouped|
          contexts = grouped.map { |bg| build_context_entry(jira_field, bg[:group], option_value:, needs_disambiguation:) }
          { jira_field:, contexts: }
        end
      end

      def build_list_registry_entries(jira_field, list_groups)
        return [] if list_groups.empty?

        needs_disambiguation = list_groups.size > 1
        contexts = list_groups.map { |group| build_context_entry(jira_field, group, needs_disambiguation:) }
        [{ jira_field:, contexts: }]
      end

      def all_jira_import_project_ids
        @all_jira_import_project_ids ||= Import::JiraProject
                                           .where(jira_import_id: @jira_import.id, origin_id: @jira_import.project_ids)
                                           .pluck(:id)
      end

      def build_contexts_for_field(jira_field)
        groups = augmented_context_groups(jira_field)
        if groups.present?
          needs_disambiguation = groups.size > 1
          groups.map { |group| build_context_entry(jira_field, group, needs_disambiguation:) }
        else
          [build_context_entry(jira_field, nil)]
        end
      end

      def augmented_context_groups(jira_field)
        groups = dup_context_groups(jira_field)
        return groups unless option_field?(jira_field)

        issue_options = issue_option_values(jira_field)
        return groups if issue_options.empty?

        groups << global_context_group if groups.empty?
        issue_options.each { |option, *scope| add_option_to_context_group(groups, option, scope) }
        groups
      end

      def dup_context_groups(jira_field)
        Array(jira_field.payload["contextGroups"]).map do |group|
          group.merge("allowedValues" => Array(group["allowedValues"]))
        end
      end

      def global_context_group
        { "projects" => [], "issuetypes" => [], "allowedValues" => [] }
      end

      def add_option_to_context_group(groups, option, scope)
        group = groups[matching_context_group_index(groups, *scope)]
        group["allowedValues"] = merge_allowed_value(group["allowedValues"], option)
      end

      def merge_allowed_value(allowed_values, option)
        label = option["value"].to_s.strip
        return allowed_values if label.blank?

        existing = allowed_values.find { |av| av["value"].to_s.strip == label }
        return allowed_values + [build_allowed_value(label, option["child"])] if existing.nil?

        merge_allowed_child(allowed_values, existing, option["child"])
      end

      def merge_allowed_child(allowed_values, existing, child)
        return allowed_values if child.blank?

        merged = existing.merge("children" => merge_allowed_value(Array(existing["children"]), child))
        allowed_values.map { |av| av.equal?(existing) ? merged : av }
      end

      def build_allowed_value(label, child)
        entry = { "value" => label }
        entry["children"] = merge_allowed_value([], child) if child.present?
        entry
      end

      def matching_context_group_index(groups, project_key, issuetype_id)
        groups.index do |group|
          scope_applies?(group["projects"], project_key) && scope_applies?(group["issuetypes"], issuetype_id)
        end || 0
      end

      def option_labels(allowed_values)
        Array(allowed_values).pluck("value").compact.map { |value| value.to_s.strip }.compact_blank.uniq
      end

      def issue_option_values(jira_field)
        issue_field_values_index[:options][jira_field.origin_id].values
      end

      def issue_string_values(jira_field)
        issue_field_values_index[:strings][jira_field.origin_id].to_a.sort
      end

      def issue_field_values_index
        @issue_field_values_index ||= build_issue_field_values_index
      end

      def new_issue_field_values_index
        { used_keys: Set.new, options: Hash.new { |h, k| h[k] = {} }, strings: Hash.new { |h, k| h[k] = Set.new } }
      end

      def build_issue_field_values_index
        index = new_issue_field_values_index
        Import::JiraIssue
          .where(jira_import_id: @jira_import.id,
                 jira_project_id: all_jira_import_project_ids)
          .find_each do |issue|
          scope = issue_context_scope(issue)
          used_custom_field_values(issue).each { |field_key, raw| record_issue_field_values(index, field_key, raw, scope) }
        end
        index
      end

      def issue_context_scope(issue)
        [issue.payload.dig("fields", "project", "key"), issue.payload.dig("fields", "issuetype", "id")]
      end

      def used_custom_field_values(issue)
        issue.payload["fields"].select { |field_key, raw| field_key.start_with?("customfield_") && raw.present? }
      end

      def record_issue_field_values(index, field_key, raw, scope)
        index[:used_keys] << field_key
        Array.wrap(raw).each do |value|
          if value.is_a?(Hash)
            record_issue_option_value(index[:options][field_key], value, scope)
          elsif raw.is_a?(Array) && value.is_a?(String)
            index[:strings][field_key] << value.strip if value.strip.present?
          end
        end
      end

      def record_issue_option_value(field_options, option, scope)
        return if option["value"].blank?

        field_options[scope + [option_chain_signature(option)]] ||= [option, *scope]
      end

      def option_chain_signature(option)
        labels = []
        node = option
        while node.is_a?(Hash) && node["value"].present?
          labels << node["value"].to_s.strip
          node = node["child"]
        end
        labels.join(" / ")
      end

      def build_context_entry(jira_field, context_group, option_value: nil, needs_disambiguation: false)
        builder = JiraImportCustomFieldBuilder.new(
          jira_field,
          context_group:,
          option_value:,
          needs_disambiguation:,
          jira_import: @jira_import,
          context_index: next_context_index(jira_field)
        )

        jira_import = jira_field.jira_import
        lock_key = "jira_import_#{jira_import.id}_find_or_create_custom_field"
        custom_field = OpenProject::Mutex.with_advisory_lock(jira_import, lock_key) do
          find_or_create_custom_field(jira_field, builder)
        end
        {
          projects: Array(context_group&.dig("projects")),
          issuetypes: Array(context_group&.dig("issuetypes")),
          custom_field:,
          builder:
        }
      end

      def run_custom_field_ids
        @run_custom_field_ids ||= Set.new
      end

      # Position of a context group among all context groups built for a Jira field, in the order
      # build_registry_entries_for_field produces them. Identifies which of the custom fields
      # already created for that Jira field belongs to this context group.
      def next_context_index(jira_field)
        @context_indexes ||= Hash.new(0)
        index = @context_indexes[jira_field.id]
        @context_indexes[jira_field.id] = index + 1
        index
      end

      def find_or_create_custom_field(jira_field, builder)
        existing_cf = builder.find_existing_custom_field(run_custom_field_ids:)
        custom_field = if existing_cf
                         reuse_custom_field(existing_cf, jira_field, builder)
                       else
                         create_custom_field(jira_field, builder)
                       end
        run_custom_field_ids << custom_field.id
        custom_field
      end

      def reuse_custom_field(custom_field, jira_field, builder)
        unless Import::JiraOpenProjectReference.exists?(op_entity_id: custom_field.id,
                                                        op_entity_class: custom_field.class.to_s,
                                                        jira_import_id: @jira_import.id)
          create_reference!(op_leg: custom_field, jira_leg: jira_field, jira_import: @jira_import, uses_existing: true)
        end
        builder.apply_pending_value_extension(custom_field, user: @system_user)
        custom_field
      end

      def create_custom_field(jira_field, builder)
        name, field_format = builder.custom_field_settings
        params = {
          type: "WorkPackageCustomField",
          name:,
          field_format:,
          is_required: false,
          is_for_all: false,
          **builder.custom_field_parameters
        }
        service_call = CustomFields::CreateService.new(user: @system_user).call(**params)
        unless service_call.success?
          raise I18n.t(
            "admin.jira.errors.custom_field_creation_failed",
            name: jira_field.payload["name"],
            message: service_call.message
          )
        end

        custom_field = service_call.result
        create_reference!(op_leg: custom_field, jira_leg: jira_field, jira_import: @jira_import, uses_existing: false)
        builder.custom_field_post_processing(custom_field)
        custom_field
      end

      # Picks the context entry whose (projects, issuetypes) match the issue's project key and
      # issue type id. Falls back to the first context if none matches - which can happen when
      # editmeta did not see the field for this (project, issuetype) pair but the issue still
      # carries a value for it (e.g. the field was removed from the screen after the value was
      # set). Falling back keeps the value rather than dropping it silently.
      def find_context_for_issue(entry, jira_issue)
        project_key = jira_issue.payload.dig("fields", "project", "key")
        issuetype_id = jira_issue.payload.dig("fields", "issuetype", "id")
        entry[:contexts].find do |ctx|
          context_applies_to_project?(ctx, project_key) && context_applies_to_issuetype?(ctx, issuetype_id)
        end || entry[:contexts].first
      end

      def context_applies_to_project?(context, project_key)
        scope_applies?(context[:projects], project_key)
      end

      def context_applies_to_issuetype?(context, issuetype_id)
        scope_applies?(context[:issuetypes], issuetype_id)
      end

      # An empty scope means "applies to all projects" / "applies to all issue types".
      def scope_applies?(scope, value)
        scope = Array(scope)
        scope.empty? || scope.include?(value)
      end
    end
  end
end

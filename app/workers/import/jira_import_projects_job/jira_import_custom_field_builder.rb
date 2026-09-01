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
  class JiraImportProjectsJob
    # Builds OpenProject custom field definition(s) from a Jira custom field
    # and an optional Jira "field context" group.
    class JiraImportCustomFieldBuilder
      JIRA_SUPPORTED_FIELDS = [
        {
          "type" => "option",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select"
        },
        {
          "type" => "option",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:radiobuttons"
        },
        {
          "type" => "array",
          "items" => "option",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiselect"
        },
        {
          "type" => "array",
          "items" => "option",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multicheckboxes"
        },
        {
          "type" => "datetime",
          "custom" => "com.onresolve.jira.groovy.groovyrunner:scripted-field"
        },
        {
          "type" => "date",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:datepicker"
        },
        {
          "type" => "datetime",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:datetime"
        },
        {
          "type" => "string",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:url"
        },
        {
          "type" => "string",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textarea"
        },
        {
          "type" => "string",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield"
        },
        {
          "type" => "number",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:float"
        },
        {
          "type" => "user",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:userpicker"
        },
        {
          "type" => "array",
          "items" => "user",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiuserpicker"
        },
        {
          "type" => "option-with-child",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:cascadingselect"
        },
        {
          "type" => "array",
          "items" => "string",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:multiselect"
        },
        {
          "type" => "array",
          "items" => "string",
          "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:labels"
        }
      ].freeze

      # Maps the Jira schema `custom` field suffix (part after the last `:`) to an OP field format.
      # Takes precedence over the type-based mapping below.
      JIRA_CUSTOM_SUFFIX_TO_OP_FORMAT = {
        "url" => "link",
        "userpicker" => "user",
        "multiuserpicker" => "user",
        "textarea" => "text" # TODO: format depends on the renderer for which no API endpoint exists to find out
      }.freeze

      # Maps the Jira schema `type` field to an OP field format.
      JIRA_TYPE_TO_OP_FORMAT = {
        "string" => "string",
        "text" => "text",
        "number" => "float",
        "date" => "date",
        "datetime" => "date", # TODO: loss of precision
        "option" => "list",
        "user" => "user",
        "any" => "string"
      }.freeze

      # Maps the Jira schema `items` field (for array types) to an OP field format.
      JIRA_ARRAY_ITEMS_TO_OP_FORMAT = {
        "option" => "list",
        "string" => "list",
        "user" => "user"
      }.freeze

      # Picks how a same-name candidate is matched when Jira Field Contexts have split one
      # Jira field into several OP custom fields: `:subset` (needed values already covered),
      # `:exact` (identical option set) or `:extend` (best overlap, missing values appended).
      VALUE_MATCH_MODE = :subset

      def self.supported?(jira_field)
        schema = jira_field.payload["schema"] || {}
        JIRA_SUPPORTED_FIELDS.any? do |entry|
          schema["type"] == entry["type"] &&
            (entry["items"].nil? || schema["items"] == entry["items"]) &&
            (entry["custom"].nil? || schema["custom"] == entry["custom"])
        end
      end

      attr_reader :jira_field, :context_group

      def initialize(jira_field, context_group: nil, option_value: nil, needs_disambiguation: false, jira_import: nil)
        @jira_field = jira_field
        @context_group = context_group
        @option_value = option_value
        @needs_disambiguation = needs_disambiguation
        @jira_import = jira_import
        @import_name = default_cf_name
      end

      def find_existing_custom_field(run_custom_field_ids: [])
        @pending_value_extension = nil
        match = best_matching_candidate(compatible_candidates, run_custom_field_ids)
        return match if match

        @import_name = unique_custom_field_name
        nil
      end

      def custom_field_settings
        [@import_name, format]
      end

      def custom_field_parameters
        case format
        when "list"
          list_field_parameters
        when "user"
          { multi_value: jira_field_multi_value? }
        else
          {}
        end
      end

      # Converts a single raw Jira field value (as found in `issue.payload["fields"][field_key]`)
      # into the value to assign to the OP custom field attribute.
      def convert_value(raw_value, custom_field)
        case format
        when "bool" then convert_multicheckbox_bool_value(raw_value)
        when "text" then JiraWikiMarkupConverter.new(raw_value.to_s).convert
        when "list" then convert_list_value(raw_value, custom_field)
        when "user" then convert_user_value(raw_value)
        when "hierarchy" then convert_hierarchy_value(raw_value, custom_field)
        else convert_fallback_value(raw_value)
        end
      end

      def custom_field_post_processing(custom_field)
        populate_hierarchy_items(custom_field) if format == "hierarchy"
      end

      def apply_pending_value_extension(custom_field, user:)
        return if @pending_value_extension.blank?

        extend_custom_field_values!(custom_field, @pending_value_extension, user:)
      end

      def format
        @format ||= @option_value ? "bool" : jira_to_op_field_format(jira_field)
      end

      private

      def stable_base_name
        base_name = jira_field.payload["name"]
        @option_value ? "#{base_name} - #{@option_value}" : base_name
      end

      def default_cf_name
        base_name = stable_base_name
        project_keys = context_group_projects
        return base_name if project_keys.empty? || !@needs_disambiguation

        "#{base_name} (#{project_keys.join(', ')})"
      end

      def context_group_projects
        Array(@context_group&.dig("projects"))
      end

      def context_group_allowed_values
        Array(@context_group&.dig("allowedValues"))
      end

      def list_field_parameters
        # In Jira DC, a single custom field can be bound to different allowed-values sets via
        # per-project and per-issuetype Field Contexts. Each distinct option set becomes its
        # own OP custom field, so one `JiraField` can produce several OP CFs. A context group
        # is a hash of the shape:
        #
        #     {
        #       "projects"      => ["DYX", "ABC"],   # Jira project keys sharing this option set
        #       "issuetypes"    => ["10100"],        # Jira issue type ids sharing this option set
        #       "allowedValues" => [{ "value" => "Low" }, ...]
        #     }
        #
        # An empty `projects` / `issuetypes` array means the context applies to all projects /
        # all issue types (used for non-list fields too, where no context discrimination exists).
        params = { multi_value: jira_field_multi_value? }
        options = list_field_option_values
        params[:possible_values] = options if options.any?
        params
      end

      def jira_field_multi_value?
        schema = jira_field.payload["schema"] || {}
        return true if schema["type"] == "option-with-child"

        schema["type"] == "array" && JIRA_ARRAY_ITEMS_TO_OP_FORMAT.key?(schema["items"])
      end

      # Returns the flat list of option labels for this list field's context group.
      # For cascading selects the tree is fully flattened so every level becomes an option.
      def list_field_option_values
        allowed = context_group_allowed_values
        if cascading_select_as_list?
          flatten_cascading_allowed_values(allowed)
        else
          allowed.pluck("value").compact.map { |value| option_label(value) }.compact_blank.uniq
        end
      end

      def option_label(value)
        value.to_s.strip
      end

      def cascading_select_as_list?
        schema = jira_field.payload["schema"] || {}
        schema["custom"].to_s.end_with?(":cascadingselect") &&
          !EnterpriseToken.allows_to?(:custom_field_hierarchies)
      end

      # Recursively collects every node as a full path label at every level of the cascading tree.
      # E.g. Animals -> ["Animals"], Animals / Cat -> ["Animals", "Animals / Cat"]
      def flatten_cascading_allowed_values(allowed_values, parent_path: nil)
        allowed_values.flat_map do |av|
          label = option_label(av["value"])
          next [] if label.blank?

          full_path = parent_path ? "#{parent_path} / #{label}" : label
          [full_path] + flatten_cascading_allowed_values(Array(av["children"]), parent_path: full_path)
        end.uniq
      end

      # Matches `Example`, `Example (2)`, `Example (DYX)` and `Example (DYX, ABC)
      def candidate_custom_fields
        base_name = stable_base_name
        escaped = ActiveRecord::Base.sanitize_sql_like(base_name)
        WorkPackageCustomField
          .where("LOWER(name) = LOWER(?)", base_name)
          .or(WorkPackageCustomField.where("name ILIKE ?", "#{escaped} (%"))
          .order(:id)
      end

      def compatible_candidates
        candidate_custom_fields.select { |cf| cf.field_format == format && compatible_multi_value?(cf) }
      end

      def compatible_multi_value?(custom_field)
        return true unless %w[list user].include?(format)

        custom_field.multi_value? == jira_field_multi_value?
      end

      def best_matching_candidate(candidates, run_custom_field_ids)
        return best_value_bearing_candidate(candidates, run_custom_field_ids) if value_bearing_format?

        candidates.find { |cf| cf.name.casecmp?(@import_name) } ||
          candidates.find { |cf| cf.name.casecmp?(stable_base_name) } ||
          candidates.first
      end

      def value_bearing_format?
        %w[list hierarchy].include?(format)
      end

      def best_value_bearing_candidate(candidates, run_custom_field_ids)
        needed = needed_value_labels.to_set
        return nil if needed.empty?

        same_run, other_runs = candidates.partition { |cf| run_custom_field_ids.include?(cf.id) }
        exact_match(same_run, needed) || match_by_mode(other_runs, needed)
      end

      def match_by_mode(candidates, needed)
        case VALUE_MATCH_MODE
        when :exact then exact_match(candidates, needed)
        when :extend then extend_best_overlapping_candidate(candidates, needed)
        else candidates.find { |cf| needed.subset?(existing_value_labels(cf).to_set) }
        end
      end

      def exact_match(candidates, needed)
        candidates.find { |cf| existing_value_labels(cf).to_set == needed }
      end

      def needed_value_labels
        format == "hierarchy" ? flatten_cascading_allowed_values(context_group_allowed_values) : list_field_option_values
      end

      def existing_value_labels(custom_field)
        labels = format == "hierarchy" ? hierarchy_labels(custom_field) : custom_field.custom_options.pluck(:value)
        labels.map { |label| option_label(label) }.compact_blank
      end

      def hierarchy_labels(custom_field)
        root = custom_field.hierarchy_root
        return [] if root.nil?

        CustomFields::Hierarchy::HierarchicalItemService
          .new
          .get_descendants(item: root, include_self: false)
          .fmap { |items| items.map(&:ancestry_path) }
          .value_or([])
      end

      def extend_best_overlapping_candidate(candidates, needed)
        scored = candidates.filter_map { |cf| score_extension_candidate(cf, needed) }
        return nil if scored.empty?

        candidate, existing = scored.min_by { |cf, values| [-(needed & values).size, cf.id] }
        @pending_value_extension = needed - existing
        candidate
      end

      def score_extension_candidate(custom_field, needed)
        existing = existing_value_labels(custom_field).to_set
        return unless needed.intersect?(existing)

        [custom_field, existing] if needed.subset?(existing) || import_owned?(custom_field)
      end

      def import_owned?(custom_field)
        Import::JiraOpenProjectReference.exists?(
          op_entity_id: custom_field.id,
          op_entity_class: custom_field.class.to_s,
          jira_id: @jira_import.jira_id
        )
      end

      def extend_custom_field_values!(custom_field, missing_labels, user:)
        return if missing_labels.empty?

        if format == "hierarchy"
          extend_hierarchy_values!(custom_field, missing_labels)
        else
          extend_list_values!(custom_field, missing_labels, user:)
        end
      end

      def extend_list_values!(custom_field, missing_labels, user:)
        values = custom_field.custom_options.pluck(:value) + missing_labels.to_a
        service_call = CustomFields::UpdateService.new(user:, model: custom_field).call(possible_values: values)
        raise service_call.message if service_call.failure?
      end

      def extend_hierarchy_values!(custom_field, missing_labels)
        custom_field.reload
        root = custom_field.hierarchy_root
        return unless root

        service = CustomFields::Hierarchy::HierarchicalItemService.new
        contract = CustomFields::Hierarchy::InsertListItemContract
        context_group_allowed_values.each do |option|
          insert_missing_hierarchy_option(service, contract, root, option, missing_labels)
        end
      end

      def insert_missing_hierarchy_option(service, contract, parent, option, missing_labels, parent_path: nil)
        label = option_label(option["value"])
        return if label.blank?

        full_path = parent_path ? "#{parent_path} / #{label}" : label
        item = parent.children.find_by(label:)
        item = insert_hierarchy_item(service, contract, parent, label) if item.nil? && missing_labels.include?(full_path)
        return unless item

        Array(option["children"]).each do |child_option|
          insert_missing_hierarchy_option(service, contract, item, child_option, missing_labels, parent_path: full_path)
        end
      end

      def custom_field_by_name(name)
        WorkPackageCustomField.where("LOWER(name) = LOWER(?)", name).first
      end

      def unique_custom_field_name
        unique_name = @import_name
        suffix = 2
        while custom_field_by_name(unique_name)
          unique_name = "#{@import_name} (#{suffix})"
          suffix += 1
        end
        unique_name
      end

      def jira_to_op_field_format(jira_field)
        schema = jira_field.payload["schema"] || {}
        type = schema["type"]
        custom_suffix = schema["custom"].to_s.split(":").last

        if type == "array"
          JIRA_ARRAY_ITEMS_TO_OP_FORMAT.fetch(schema["items"], "string")
        elsif custom_suffix == "cascadingselect"
          EnterpriseToken.allows_to?(:custom_field_hierarchies) ? "hierarchy" : "list"
        else
          JIRA_CUSTOM_SUFFIX_TO_OP_FORMAT[custom_suffix] || JIRA_TYPE_TO_OP_FORMAT.fetch(type, "string")
        end
      end

      def convert_multicheckbox_bool_value(raw_value)
        return false unless raw_value.is_a?(Array)

        raw_value.any? { |v| option_label(v["value"]) == @option_value }
      end

      def convert_user_value(raw_value)
        if raw_value.is_a?(Array)
          raw_value.filter_map { |u| find_field_user(u["key"]) }
        else
          find_field_user(raw_value["key"])
        end
      end

      def convert_list_value(raw_value, custom_field)
        if cascading_select_as_list? && raw_value.is_a?(Hash)
          convert_cascading_list_value(raw_value, custom_field)
        elsif raw_value.is_a?(Array)
          convert_array_list_value(raw_value, custom_field)
        else
          convert_single_list_value(raw_value, custom_field)
        end
      end

      def convert_cascading_list_value(raw_value, custom_field)
        extract_cascading_chain(raw_value).filter_map { |label| custom_field.value_of(label) }
      end

      def convert_array_list_value(raw_value, custom_field)
        raw_value.filter_map do |c_value|
          label = extract_list_label(c_value)
          custom_field.value_of(label)
        end
      end

      def convert_single_list_value(raw_value, custom_field)
        label = extract_list_label(raw_value)
        custom_field.value_of(label)
      end

      def extract_list_label(value)
        option_label(value.is_a?(Hash) ? value["value"] : value)
      end

      # Walks the parent -> child chain of a cascading select value, returning
      # full path labels from root down to the deepest selected child.
      # E.g. {value: "Animals", child: {value: "Cat"}} -> ["Animals", "Animals / Cat"]
      def extract_cascading_chain(value, parent_path: nil)
        return [] unless value.is_a?(Hash) && value["value"].present?

        label = option_label(value["value"])
        full_path = parent_path ? "#{parent_path} / #{label}" : label
        [full_path] + extract_cascading_chain(value["child"], parent_path: full_path)
      end

      def populate_hierarchy_items(custom_field)
        custom_field.reload
        root = custom_field.hierarchy_root
        return unless root

        service = CustomFields::Hierarchy::HierarchicalItemService.new
        contract = CustomFields::Hierarchy::InsertListItemContract

        context_group_allowed_values.each do |parent_option|
          insert_hierarchy_option(service, contract, root, parent_option)
        end
      end

      def insert_hierarchy_option(service, contract, parent, option)
        label = option_label(option["value"])
        return if label.blank?

        item = insert_hierarchy_item(service, contract, parent, label)
        return unless item

        Array(option["children"]).each do |child_option|
          insert_hierarchy_option(service, contract, item, child_option)
        end
      end

      def insert_hierarchy_item(service, contract, parent, label)
        result = service.insert_item(contract_class: contract, parent:, label:)
        result.success? ? result.value! : nil
      end

      # Fallback for scalar formats (string, float, date, link). Hash values
      # (e.g. cascading selects without enterprise) are converted to a readable
      # "Parent - Child" string instead of their Ruby Hash#to_s representation.
      def convert_fallback_value(raw_value)
        return raw_value unless raw_value.is_a?(Hash)

        label = raw_value["value"].to_s
        child_label = raw_value.dig("child", "value")
        child_label.present? ? "#{label} - #{child_label}" : label
      end

      def convert_hierarchy_value(raw_value, custom_field)
        return unless raw_value.is_a?(Hash)

        root = custom_field.hierarchy_root
        return unless root

        parent_item = root.children.find_by(label: option_label(raw_value["value"]))
        return unless parent_item

        find_hierarchy_child(parent_item, raw_value["child"])&.id || parent_item.id
      end

      def find_hierarchy_child(parent_item, child_data)
        return unless child_data.is_a?(Hash) && child_data["value"].present?

        parent_item.children.find_by(label: option_label(child_data["value"]))
      end

      def find_field_user(jira_user_key)
        return if jira_user_key.blank?

        jira_user = Import::JiraUser.find_by(jira_user_key:, jira_import: @jira_import)
        if jira_user
          JiraOpenProjectReference.find_by!(
            jira_entity_class: "Import::JiraUser",
            jira_entity_id: jira_user.id
          ).op_leg
        end
      end
    end
  end
end

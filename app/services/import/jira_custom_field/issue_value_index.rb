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
  module JiraCustomField
    # The values imported issues carry for custom fields, in the shape the custom field registry
    # consumes:
    #
    #   { used_keys: Set["customfield_10001", ...],
    #     options:   { "customfield_10001" => [[option, [scope, ...]], ...] },
    #     strings:   { "customfield_10002" => ["a", "b"] },
    #     scopes:    { "customfield_10001" => [scope, ...] } }
    #
    # where a scope is [project_key, jira_project_id, issuetype_id]. An option is held once with
    # the scopes it occurs in, rather than once per scope: a field offering the same options
    # throughout a large run would otherwise store them again for every project and issue type.
    # `serialize` shortens the scopes of an option to their positions in the field's `scopes`.
    #
    class IssueValueIndex
      # Only the parts of an issue the index reads. `custom_fields` is NULL for an issue carrying none
      ISSUE_PROJECTION = <<~'SQL'.squish
        jira_issues.id,
        jira_issues.jira_project_id,
        jira_issues.payload #>> '{fields,project,key}' AS project_key,
        jira_issues.payload #>> '{fields,issuetype,id}' AS issuetype_id,
        (SELECT jsonb_object_agg(key, value)
           FROM jsonb_each(jira_issues.payload -> 'fields')
          WHERE key LIKE 'customfield\_%') AS custom_fields
      SQL

      SAMPLE_ISSUE_PROJECTION = <<~SQL.squish
        jira_issues.id,
        jira_issues.origin_id,
        jira_issues.payload #>> '{key}' AS issue_key,
        jira_issues.payload #>> '{fields,project,key}' AS project_key,
        jira_issues.payload #>> '{fields,issuetype,id}' AS issuetype_id
      SQL

      class << self
        def scan(jira_import)
          index = new_index
          issues(jira_import, ISSUE_PROJECTION).find_each { |issue| record_issue(index, issue) }
          finalize(index)
        end

        # One issue key per (project, issue type) pair, for the routes that have to read a context
        # off an issue. Queried rather than carried in the index, so that it does not matter
        # whether the index was scanned or loaded from an earlier stage.
        def sample_issue_keys(jira_import)
          samples = {}
          issues(jira_import, SAMPLE_ISSUE_PROJECTION).find_each do |issue|
            samples[[issue["project_key"], issue["issuetype_id"]]] ||= issue["issue_key"] || issue["origin_id"]
          end
          samples
        end

        def load(jira_import)
          stored = Import::JiraField.where(jira_import_id: jira_import.id).pluck(:origin_id, :issue_values)
          return nil if stored.any? { |_origin_id, values| values.nil? }

          stored.each_with_object(loaded_index) do |(origin_id, values), index|
            record_stored_field(index, origin_id, values)
          end
        end

        def serialize(index)
          index[:used_keys].index_with do |field_key|
            scopes = index[:scopes].fetch(field_key, [])
            { "used" => true,
              "options" => serialized_options(index[:options].fetch(field_key, []), scopes),
              "strings" => index[:strings].fetch(field_key, []),
              "scopes" => scopes }
          end
        end

        private

        def record_stored_field(index, origin_id, values)
          return unless values["used"]

          scopes = Array(values["scopes"])
          index[:used_keys] << origin_id
          index[:options][origin_id] = stored_options(Array(values["options"]), scopes)
          index[:strings][origin_id] = Array(values["strings"])
          index[:scopes][origin_id] = scopes
        end

        def serialized_options(options, scopes)
          positions = scopes.each_with_index.to_h
          options.map { |option, option_scopes| [option, option_scopes.filter_map { |scope| positions[scope] }] }
        end

        def stored_options(options, scopes)
          options.map { |option, positions| [option, Array(positions).filter_map { |position| scopes[position] }] }
        end

        def issues(jira_import, projection)
          project_ids = Import::JiraProject
                          .where(jira_import_id: jira_import.id, origin_id: jira_import.project_ids)
                          .pluck(:id)
          Import::JiraIssue
            .where(jira_import_id: jira_import.id, jira_project_id: project_ids)
            .select(Arel.sql(projection))
        end

        def new_index
          { used_keys: Set.new,
            options: Hash.new { |hash, key| hash[key] = {} },
            strings: Hash.new { |hash, key| hash[key] = Set.new },
            scopes: Hash.new { |hash, key| hash[key] = Set.new } }
        end

        def loaded_index
          { used_keys: Set.new, options: {}, strings: {}, scopes: {} }
        end

        def finalize(index)
          index.merge(
            options: index[:options].transform_values { |chains| chains.values.map { |o, scopes| [o, scopes.to_a] } },
            strings: index[:strings].transform_values { |values| values.to_a.sort },
            scopes: index[:scopes].transform_values(&:to_a)
          )
        end

        def record_issue(index, issue)
          scope = [issue["project_key"], issue["jira_project_id"], issue["issuetype_id"]]
          (issue["custom_fields"] || {}).each do |field_key, raw_value|
            next if raw_value.blank?

            record_field_value(index, field_key, raw_value, scope)
          end
        end

        def record_field_value(index, field_key, raw_value, scope)
          index[:used_keys] << field_key
          index[:scopes][field_key] << scope
          Array.wrap(raw_value).each do |value|
            if value.is_a?(Hash)
              record_option(index[:options][field_key], value, scope)
            elsif raw_value.is_a?(Array)
              record_string(index[:strings][field_key], value)
            end
          end
        end

        def record_string(field_strings, value)
          return unless value.is_a?(String) && value.strip.present?

          field_strings << value.strip
        end

        def record_option(field_options, option, scope)
          return if option["value"].blank?

          chain = option_chain(option).join(" / ")
          entry = field_options[chain] ||= [pruned_option(option), Set.new]
          entry.last << scope
        end

        def pruned_option(option)
          pruned = { "value" => option["value"] }
          pruned["child"] = pruned_option(option["child"]) if option["child"].is_a?(Hash)
          pruned
        end

        def option_chain(option)
          labels = []
          node = option
          while node.is_a?(Hash) && node["value"].present?
            labels << node["value"].to_s.strip
            node = node["child"]
          end
          labels
        end
      end
    end
  end
end

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

module JsonForms
  # Server-side implementation of the JSON Forms UI schema concepts we support:
  # generated layouts, control scopes and rules.
  module UiSchema
    DOCS_URL = "https://jsonforms.io/docs/uischema"

    module_function

    def generate(schema)
      if schema["type"] == "object"
        properties = schema.fetch("properties", {}).keys
        { "type" => "VerticalLayout",
          "elements" => properties.map { { "type" => "Control", "scope" => "#/properties/#{it}" } } }
      else
        { "type" => "Control", "scope" => "#", "label" => false }
      end
    end

    # "#/properties/contact/properties/zip" => ["contact", "zip"]
    def scope_keys(scope)
      scope.to_s.delete_prefix("#").split("/").reject(&:empty?).each_slice(2).map(&:last)
    end

    def schema_at(schema, keys)
      keys.reduce(schema) { |current, key| current&.dig("properties", key) }
    end

    # The schema of the value at a data path, following array items and additional properties.
    def schema_for_data_path(schema, keys)
      keys.reduce(schema) do |current, key|
        break unless current.is_a?(Hash)

        if current["type"] == "array" then current["items"]
        elsif current.dig("properties", key) then current["properties"][key]
        else additional_properties_schema(current)
        end
      end
    end

    # The schema for values of properties not listed in "properties", if the object allows them explicitly.
    # `"additionalProperties": true` accepts any value, which the form offers as text.
    def additional_properties_schema(schema)
      case schema["additionalProperties"]
      when Hash then schema["additionalProperties"]
      when true then { "type" => "string" }
      end
    end

    def visible?(element, data)
      case element.dig("rule", "effect")
      when "SHOW" then condition_matches?(element["rule"]["condition"], data)
      when "HIDE" then !condition_matches?(element["rule"]["condition"], data)
      else true
      end
    end

    def enabled?(element, data)
      case element.dig("rule", "effect")
      when "ENABLE" then condition_matches?(element["rule"]["condition"], data)
      when "DISABLE" then !condition_matches?(element["rule"]["condition"], data)
      else true
      end
    end

    def condition_matches?(condition, data)
      return false unless condition.is_a?(Hash)

      case condition["type"]
      when "AND" then Array(condition["conditions"]).all? { condition_matches?(it, data) }
      when "OR" then Array(condition["conditions"]).any? { condition_matches?(it, data) }
      else schema_condition_matches?(condition, data)
      end
    end

    def schema_condition_matches?(condition, data)
      value = FormData.dig(data, scope_keys(condition["scope"]))
      !value.nil? && JSONSchemer.schema(condition.fetch("schema", {})).valid?(value)
    end

    # Scopes (as key lists) that any rule in the UI schema depends on.
    def rule_scopes(element)
      return [] unless element.is_a?(Hash)

      children = Array(element["elements"]) + [element.dig("options", "detail")].compact
      condition_scopes(element.dig("rule", "condition")) + children.flat_map { rule_scopes(it) }
    end

    def condition_scopes(condition)
      return [] unless condition.is_a?(Hash)
      return condition["conditions"].flat_map { condition_scopes(it) } if condition["conditions"]

      [scope_keys(condition["scope"])]
    end
  end
end

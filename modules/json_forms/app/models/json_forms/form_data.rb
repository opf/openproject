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
  # Converts between submitted form parameters and the JSON data described by a JSON Schema.
  module FormData
    module_function

    def dig(data, keys)
      keys.reduce(data) do |current, key|
        case current
        when Hash then current[key]
        when Array then current[Integer(key, exception: false) || -1]
        end
      end
    end

    def apply_defaults(schema, data)
      return data unless schema.is_a?(Hash) && schema["properties"].is_a?(Hash) && data.is_a?(Hash)

      schema["properties"].each_with_object(data.dup) do |(key, property), result|
        value = result[key].nil? ? default_for(property) : apply_defaults(property, result[key])
        value.nil? ? result.delete(key) : result[key] = value
      end
    end

    def default_for(property)
      property["default"].deep_dup if property.is_a?(Hash)
    end

    # Form parameters are strings, and arrays arrive as hashes keyed by index ("0", "1", ...).
    def coerce(schema, raw)
      return raw unless schema.is_a?(Hash)

      case schema["type"]
      when "object" then coerce_object(schema, raw)
      when "array" then coerce_array(schema, raw)
      when "boolean" then truthy?(raw)
      when "integer", "number" then coerce_number(schema["type"], raw)
      else raw.is_a?(String) ? raw.presence : raw
      end
    end

    def truthy?(raw)
      ["1", "true", true].include?(raw)
    end

    def coerce_object(schema, raw)
      return unless raw.is_a?(Hash)

      properties = schema.fetch("properties", {})
      result = properties.each_with_object({}) do |(key, property), declared|
        next unless raw.key?(key)

        value = coerce(property, raw[key])
        declared[key] = value unless value.nil?
      end
      result.merge(coerce_additional_properties(schema, raw.except(*properties.keys)))
    end

    # Additional properties are kept even while empty, so a newly added one doesn't vanish on the next refresh.
    def coerce_additional_properties(schema, raw)
      value_schema = UiSchema.additional_properties_schema(schema)
      return {} unless value_schema

      raw.each_with_object({}) do |(key, value), result|
        result[key] = coerce(value_schema, value) || empty_item(value_schema) if valid_property_name?(key)
      end
    end

    def valid_property_name?(name)
      name.is_a?(String) && name.present? && !name.match?(/[.\[\]]/)
    end

    def coerce_array(schema, raw)
      items = raw.is_a?(Hash) ? raw.sort_by { |index, _| index.to_i }.map(&:last) : Array(raw)
      item_schema = schema["items"]
      return items.compact_blank.map { coerce(item_schema, it) } if Options.for(item_schema)

      items.map { coerce(item_schema, it) || empty_item(item_schema) }
    end

    def coerce_number(type, raw)
      return if raw.blank?
      return Integer(raw.to_s, 10) if type == "integer"

      Float(raw.to_s).then { (it % 1).zero? ? it.to_i : it }
    rescue ArgumentError
      raw
    end

    # The value a newly added array row starts with.
    def empty_item(schema)
      case schema.is_a?(Hash) && schema["type"]
      when "object" then {}
      when "string" then ""
      end
    end

    # Applies an Add/Remove button:
    # "add:tasks" appends a row, "remove:tasks.1" removes the second one,
    # "add_property:contact" adds the property `property_name` to the object, "remove:contact.phone" removes it.
    # Raises InvalidPropertyName when the new property's name is not acceptable.
    def apply_operation(schema, data, operation, property_name: nil)
      action, path = operation.to_s.split(":", 2)
      keys = path.to_s.split(".")
      data = data.deep_dup
      case action
      when "add" then add_item(schema, data, keys) if keys.any?
      when "add_property" then add_property(schema, data, keys, property_name.to_s.strip)
      when "remove" then remove(data, keys) if keys.any?
      end
      data
    end

    class InvalidPropertyName < StandardError; end

    def add_item(schema, data, keys)
      parent = dig(data, keys[0..-2])
      return unless parent.is_a?(Hash) || parent.is_a?(Array)

      key = key_in(parent, keys.last)
      parent[key] = [] unless parent[key].is_a?(Array)
      parent[key] << empty_item(UiSchema.schema_for_data_path(schema, keys)&.fetch("items", nil))
    end

    def key_in(parent, key)
      parent.is_a?(Array) ? key.to_i : key
    end

    def add_property(schema, data, keys, name)
      object_schema = UiSchema.schema_for_data_path(schema, keys)
      value_schema = object_schema && UiSchema.additional_properties_schema(object_schema)
      return unless value_schema

      object = keys.empty? ? data : (dig(data, keys) || ensure_object(data, keys))
      check_property_name!(object_schema, object, name)
      object[name] = empty_item(value_schema)
    end

    def check_property_name!(object_schema, object, name)
      error = property_name_error(object_schema, object, name)
      raise InvalidPropertyName, I18n.t("json_forms.errors.#{error}") if error
    end

    def property_name_error(object_schema, object, name)
      return :property_name_blank if name.empty?
      return :property_name_invalid unless valid_property_name?(name)
      return :property_name_taken if object.key?(name) || object_schema.fetch("properties", {}).key?(name)

      allowed = object_schema["propertyNames"]
      :property_name_mismatch if allowed && !JSONSchemer.schema(allowed).valid?(name)
    end

    def ensure_object(data, keys)
      parent = dig(data, keys[0..-2])
      parent[key_in(parent, keys.last)] = {}
    end

    def remove(data, keys)
      parent = dig(data, keys[0..-2])
      case parent
      when Array then parent.delete_at(keys.last.to_i)
      when Hash then parent.delete(keys.last)
      end
    end
  end
end

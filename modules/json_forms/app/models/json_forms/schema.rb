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
  # A JSON Schema describing a form's data, see InputForm.
  class Schema
    DOCS_URL = "https://json-schema.org/understanding-json-schema"

    EMPTY = { "type" => "object", "properties" => {} }.freeze

    attr_reader :schema

    def initialize(schema)
      @schema = schema.presence || EMPTY
    end

    # Problems with the schema itself, as full sentences.
    def errors
      meta_errors = JSONSchemer.validate_schema(schema).pluck("error")
      return meta_errors.map { message(:invalid_schema, details: it) } if meta_errors.any?
      return [message(:root)] unless schema["type"] == "object"

      []
    end

    def empty?
      schema.fetch("properties", {}).blank?
    end

    # Returns the first error message per field, keyed by the field's path ("contact.address.zip").
    def validate(input) # rubocop:disable Metrics/AbcSize
      JSONSchemer.schema(schema).validate(input).each_with_object({}) do |error, messages|
        keys = error["data_pointer"].split("/").drop(1)
        if error["type"] == "required"
          error.dig("details", "missing_keys").each { messages[[*keys, it].join(".")] ||= message(:blank) }
        else
          messages[keys.join(".")] ||= message_for(error)
        end
      end
    end

    private

    def message_for(error) # rubocop:disable Metrics/AbcSize
      keyword = error["type"]
      limit = error["schema"].is_a?(Hash) ? error["schema"][keyword] : nil
      case keyword
      when "minLength" then message(:min_length, count: limit)
      when "maxLength" then message(:max_length, count: limit)
      when "minimum" then message(:greater_than_or_equal_to, count: limit)
      when "exclusiveMinimum" then message(:greater_than, count: limit)
      when "maximum" then message(:less_than_or_equal_to, count: limit)
      when "exclusiveMaximum" then message(:less_than, count: limit)
      when "minItems" then message(:min_items, count: limit)
      when "maxItems" then message(:max_items, count: limit)
      when "enum", "const", "oneOf" then message(:inclusion)
      when "integer" then message(:not_an_integer)
      when "number" then message(:not_a_number)
      else message(:invalid)
      end
    end

    def message(key, **)
      I18n.t("json_forms.errors.#{key}", **)
    end
  end
end

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

module Webhooks
  class ManualScriptSchema
    Field = Data.define(:name, :kind, :title, :description, :required, :default, :options, :spec)

    OP_FORMATS = { "op-user" => :user, "op-work-package" => :work_package, "op-version" => :version }.freeze
    EMPTY = { "type" => "object", "properties" => {} }.freeze

    attr_reader :schema

    def initialize(schema)
      @schema = schema.presence || EMPTY
    end

    def errors
      meta_errors = JSONSchemer.validate_schema(schema).pluck("error")
      return meta_errors if meta_errors.any?
      return [I18n.t("webhooks.kubernetes.scripts.schema_errors.root")] unless object_with_properties?

      properties.filter_map do |name, spec|
        next if kind_for(spec)

        I18n.t("webhooks.kubernetes.scripts.schema_errors.unsupported", name:)
      end
    end

    def fields
      required = Array(schema["required"])
      properties.map do |name, spec|
        Field.new(
          name:,
          kind: kind_for(spec),
          title: spec["title"].presence || name.humanize,
          description: spec["description"],
          required: required.include?(name),
          default: spec["default"],
          options: options_for(spec["type"] == "array" ? spec["items"] : spec),
          spec:
        )
      end
    end

    def coerce(params)
      params = params.to_h.stringify_keys
      fields.each_with_object({}) do |field, input|
        next unless params.key?(field.name)

        value = coerce_value(field, params[field.name])
        input[field.name] = value unless value.nil? || value == ""
      end
    end

    def validate(input) # rubocop:disable Metrics/AbcSize
      JSONSchemer.schema(schema).validate(input).each_with_object({}) do |error, messages|
        if error["type"] == "required"
          error.dig("details", "missing_keys").each do |key|
            messages[key] ||= I18n.t("activerecord.errors.messages.blank")
          end
        else
          key = error["data_pointer"].split("/")[1]
          messages[key] ||= error["error"].sub(/ at `[^`]*`/, "")
        end
      end
    end

    private

    def coerce_value(field, raw)
      case field.kind
      when :boolean then ["1", "true", true].include?(raw)
      when :multi_select
        Array(raw).compact_blank.map { cast(field.spec.dig("items", "type"), it) }
      when :integer, :number, :select then cast(field.spec["type"], raw)
      else raw.to_s.strip
      end
    end

    def cast(type, raw)
      return raw if raw.blank?

      case type
      when "integer" then Integer(raw, 10)
      when "number" then Float(raw).then { it % 1 == 0 ? it.to_i : it }
      else raw.to_s
      end
    rescue ArgumentError, TypeError
      raw
    end

    def object_with_properties?
      schema["type"] == "object" && schema.fetch("properties", {}).is_a?(Hash)
    end

    def properties
      schema.fetch("properties", {})
    end

    def kind_for(spec) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      return unless spec.is_a?(Hash)

      case spec["type"]
      when "boolean" then :boolean
      when "integer", "number" then options_for(spec) ? :select : spec["type"].to_sym
      when "array" then :multi_select if options_for(spec["items"])
      when "string"
        if options_for(spec) then options_for(spec).size <= 4 ? :radio : :select
        elsif OP_FORMATS.key?(spec["format"]) then OP_FORMATS[spec["format"]]
        elsif spec["format"] == "date" then :date
        elsif spec["format"] == "textarea" then :textarea
        else :text
        end
      end
    end

    def options_for(spec) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
      return unless spec.is_a?(Hash)

      if spec["enum"].is_a?(Array)
        spec["enum"].map { |value| [value.to_s, value] }
      elsif spec["oneOf"].is_a?(Array) && spec["oneOf"].all? { it.is_a?(Hash) && it.key?("const") }
        spec["oneOf"].map { |option| [option["title"].presence || option["const"].to_s, option["const"]] }
      end
    end
  end
end

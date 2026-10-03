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
# frozen_string_literal: true

module FieldRules
  module Fields
    Definition = Struct.new(:key, :attributes, :schema_key, :default_type, keyword_init: true)

    CUSTOM_FIELD_KEY = /\Acustom_field_(\d+)\z/

    NATIVE = {
      "description" => Definition.new(key: "description", attributes: %w[description],
                                      schema_key: "description", default_type: :text),
      "assignee" => Definition.new(key: "assignee", attributes: %w[assigned_to_id assigned_to],
                                   schema_key: "assignee", default_type: :user),
      "responsible" => Definition.new(key: "responsible", attributes: %w[responsible_id responsible],
                                      schema_key: "responsible", default_type: :user),
      "priority" => Definition.new(key: "priority", attributes: %w[priority_id priority],
                                   schema_key: "priority", default_type: :priority),
      "category" => Definition.new(key: "category", attributes: %w[category_id category],
                                   schema_key: "category", default_type: :category),
      "target_versions" => Definition.new(key: "target_versions", attributes: %w[target_versions target_version_ids],
                                          schema_key: "targetVersions", default_type: nil),
      "start_date" => Definition.new(key: "start_date", attributes: %w[start_date],
                                     schema_key: "startDate", default_type: :date),
      "due_date" => Definition.new(key: "due_date", attributes: %w[due_date],
                                   schema_key: "dueDate", default_type: :date),
      "estimated_time" => Definition.new(key: "estimated_time", attributes: %w[estimated_hours estimated_time],
                                         schema_key: "estimatedTime", default_type: :hours)
    }.freeze

    class << self
      def registry
        @registry ||= NATIVE.dup
      end

      # Lets other modules make their own work package attributes configurable.
      def register(key, attributes:, schema_key:, default_type: nil)
        registry[key.to_s] = Definition.new(key: key.to_s, attributes: Array(attributes).map(&:to_s),
                                            schema_key:, default_type:)
      end

      def reset_registry!
        @registry = NATIVE.dup
      end

      def configurable_keys
        registry.keys + WorkPackageCustomField.order(:name).pluck(:id).map { |id| "custom_field_#{id}" }
      end

      def label(key)
        id = custom_field_id(key)
        return WorkPackageCustomField.find_by(id:)&.name || key.to_s if id

        WorkPackage.human_attribute_name(definition(key)&.attributes&.first.to_s.delete_suffix("_id"))
      end

      def labels(keys)
        names = WorkPackageCustomField.where(id: keys.filter_map { |key| custom_field_id(key) }).pluck(:id, :name).to_h
        keys.index_with { |key| names[custom_field_id(key)] || label(key) }
      end

      def custom_field_id(key)
        key.to_s[CUSTOM_FIELD_KEY, 1]&.to_i
      end

      def definition(key)
        key = key.to_s
        return registry[key] if registry.key?(key)

        id = custom_field_id(key)
        return unless id

        Definition.new(key:, attributes: [key], schema_key: "customField#{id}", default_type: :custom_field)
      end

      def configurable?(key)
        definition = definition(key)
        return false unless definition
        return true unless definition.default_type == :custom_field

        WorkPackageCustomField.exists?(id: custom_field_id(key))
      end

      def attribute_matches?(key, attribute_name)
        attribute_name = attribute_name.to_s
        id = custom_field_id(key)
        return attribute_name.match?(/\Acustom_field_#{id}(_|\z)/) if id

        definition(key)&.attributes&.include?(attribute_name) || false
      end

      def schema_key(key) = definition(key)&.schema_key

      def default_error(key, value)
        definition = definition(key)
        return :invalid_default if definition.nil? || definition.default_type.nil?

        valid = case definition.default_type
                when :text then true
                when :user then User.exists?(id: Integer(value, exception: false))
                when :priority then IssuePriority.exists?(id: Integer(value, exception: false))
                when :category then Category.exists?(id: Integer(value, exception: false))
                when :date then Date.iso8601(value.to_s) && true
                when :hours then Float(value, exception: false)&.positive? || false
                when :custom_field then custom_field_default_valid?(key, value)
                end
        valid ? nil : :invalid_default
      rescue Date::Error
        :invalid_default
      end

      def apply_default(work_package, key, value)
        definition = definition(key)
        return if definition.nil? || value.blank?

        case definition.default_type
        when :text then work_package.description = value
        when :user then work_package.public_send(key == "assignee" ? :assigned_to_id= : :responsible_id=, value.to_i)
        when :priority then work_package.priority_id = value.to_i
        when :category then work_package.category_id = value.to_i
        when :date then work_package.public_send(:"#{key}=", Date.iso8601(value))
        when :hours then work_package.estimated_hours = value.to_f
        when :custom_field then work_package.public_send(:"#{key}=", value)
        end
      end

      def blank_value?(work_package, key)
        attribute = definition(key)&.attributes&.first
        attribute.present? && work_package.respond_to?(attribute) && work_package.public_send(attribute).blank?
      end

      private

      def custom_field_default_valid?(key, value)
        custom_field = WorkPackageCustomField.find_by(id: custom_field_id(key))
        return false unless custom_field

        case custom_field.field_format
        when "int" then Integer(value, exception: false).present?
        when "float" then Float(value, exception: false).present?
        when "bool" then %w[true false 1 0 t f].include?(value.to_s)
        when "date" then Date.iso8601(value.to_s) && true
        when "list" then custom_field.possible_values.map { |v| v.id.to_s }.include?(value.to_s)
        else true
        end
      rescue Date::Error
        false
      end
    end
  end
end

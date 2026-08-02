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

module ActsAsCustomizable::CalculatedValue
  extend ActiveSupport::Concern

  included do
    def enabled_custom_field_ids
      fail NoMethodError, <<~DESCRIPTION.squish
        Required for calculated_value custom fields in calculate_custom_fields method.
        Define which fields are enabled, not to be confused with visible, as enabled should not depend on current user.
      DESCRIPTION
    end

    def calculate_custom_fields(custom_fields)
      return if custom_fields.empty?

      validate_custom_fields_for_calculation!(custom_fields)

      enabled_ids = enabled_custom_field_ids
      given = calculated_value_fields_given(custom_fields:, enabled_ids:)

      calculate_custom_fields_result(
        given:,
        to_compute: calculated_value_fields_to_compute(custom_fields:, enabled_ids:)
      ) => { result:, errors: }

      self.custom_field_values = custom_fields.to_h { [it.id, result[it.column_name]] }

      handle_calculation_errors!(given, enabled_ids, custom_fields, result, errors)
    end

    private

    def validate_custom_fields_for_calculation!(custom_fields)
      unless custom_fields.all?(&:field_format_calculated_value?)
        fail ArgumentError, "Expected array of calculated value custom fields"
      end
    end

    def calculate_custom_fields_result(given:, to_compute:)
      calculator = CustomField::CalculatedValue.calculator_instance
      calculator.store(given)

      calculation = calculator.solve(to_compute, &:itself)

      result = {}
      errors = {}

      calculation.each do |key, value|
        if CustomField::CalculatedValue.computed_value?(value)
          result[key] = value
        else
          result[key] = nil
          errors[key] = value
        end
      end

      { result:, errors: }
    end

    def calculated_value_fields_given(custom_fields:, enabled_ids:)
      referenced_ids = custom_fields.flat_map(&:formula_referenced_custom_field_ids)
      given_ids = (enabled_ids & referenced_ids) - custom_fields.map(&:id)

      custom_field_values(all: true)
        .select { it.custom_field_id.in?(given_ids) }
        .to_h { [it.custom_field.column_name, it.typed_value] }
    end

    def calculated_value_fields_to_compute(custom_fields:, enabled_ids:)
      custom_fields
        .select { it.id.in?(enabled_ids) }
        .to_h { [it.column_name, it.formula_str_without_patterns] }
    end

    def handle_calculation_errors!(given_cfs, enabled_ids, calculated_fields, result, errors)
      # Skip creating error objects if the project is not persisted, because the error objects
      # require the customized object (project) to be saved in the database.
      return unless is_a?(Project) && persisted?

      remove_calculated_value_errors!(calculated_fields.map(&:id))

      create_calculated_value_errors(given_cfs, enabled_ids, calculated_fields, result, errors)
    end

    def remove_calculated_value_errors!(custom_field_ids)
      return if custom_field_ids.empty?

      CalculatedValueError.where(customized: self, custom_field_id: custom_field_ids).delete_all
    end

    def create_calculated_value_errors(given_cfs, enabled_ids, calculated_fields, result, errors)
      return if errors.empty?

      enabled_calculated_fields = calculated_fields.filter { it.id.in?(enabled_ids) }

      CalculatedValues::ErrorHandler.handle_calculation_errors(
        customized: self,
        calculation_errors: errors,
        calculation_values: result,
        given_values: given_cfs,
        calculated_fields: enabled_calculated_fields
      )
    end
  end
end

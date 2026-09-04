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

# Methods for custom fields with a format of "calculated value".
# Should be included in the CustomField model.
module CustomField::CalculatedValue
  extend ActiveSupport::Concern

  # Math, comparison and logical operators allowed in a formula.
  # AND and OR can be used both as operators and functions.
  FORMULA_OPERATORS = %w[
    + - * / % ^
    < > <= >= <> != = ==
    AND && OR ||
  ].freeze

  # Symbols for grouping and calling functions.
  FORMULA_PUNCTUATION = %w[
    ( ) ,
  ].freeze

  # Functions allowed in a formula.
  # AND and OR can be used both as operators and functions.
  FORMULA_FUNCTIONS = %w[
    IF AND OR XOR NOT SWITCH
    MIN MAX SUM AVG ROUND ROUNDDOWN ROUNDUP ABS
  ].freeze

  # Keywords allowed in a formula.
  FORMULA_KEYWORDS = %w[
    CASE WHEN THEN ELSE END
  ].freeze

  # Boolean literals allowed in a formula.
  FORMULA_CONSTANTS = %w[
    TRUE FALSE
  ].freeze

  # Longer alternatives must come first, otherwise matching ROUND breaks matching ROUNDUP.
  FORMULA_SPLITTER = Regexp.union([
    " ",
    *FORMULA_OPERATORS,
    *FORMULA_PUNCTUATION,
    *FORMULA_FUNCTIONS,
    *FORMULA_KEYWORDS,
    *FORMULA_CONSTANTS
  ].uniq.sort_by { -it.length })
  FORMULA_TOKENS = /\A(\{\{cf_\d+}}|[\d.]+|)\z/
  private_constant :FORMULA_SPLITTER, :FORMULA_TOKENS

  # Field formats that can be used within a formula.
  FIELD_FORMATS_FOR_FORMULA = %w[int float bool calculated_value weighted_item_list].freeze

  def self.calculator_instance
    Dentaku::Calculator.new(case_sensitive: true, raw_date_literals: false)
  end

  def self.computed_value?(value)
    value in Numeric | true | false
  end

  class_methods do
    def with_formula_referencing(id)
      where("(formula -> 'referenced_custom_fields') @> ?", id)
    end

    # Select custom fields of type calculated_value that are listed in
    # changed_cf_ids, or are referencing custom fields in changed_cf_ids either
    # directly or through other calculated fields
    def affected_calculated_fields(changed_cf_ids)
      return [] if changed_cf_ids.empty?

      # exclude ids that are not in the scope
      changed_cf_ids = where(id: changed_cf_ids).pluck(:id)
      return [] if changed_cf_ids.empty?

      to_check = field_format_calculated_value

      # include calculated value fields themselves
      all_affected, to_check = to_check.partition { it.id.in?(changed_cf_ids) }

      loop do
        affected, to_check = to_check.partition { it.formula_referenced_custom_field_ids.intersect?(changed_cf_ids) }
        break if affected.empty?

        all_affected += affected
        changed_cf_ids = affected.map(&:id)
      end

      all_affected
    end
  end

  included do
    validate :validate_formula, if: :field_format_calculated_value?

    def validate_formula
      if formula_string.blank?
        errors.add(:formula, :blank)
      elsif !formula_contains_only_allowed_tokens?
        errors.add(:formula, :invalid_tokens)
      elsif !valid_formula_syntax?
        errors.add(:formula, :invalid)
      else
        validate_referenced_custom_fields
      end
    end

    def formula=(value)
      if value.is_a?(String)
        super({ formula: value, referenced_custom_fields: cf_ids_used_in_formula(value) })
      else
        super
      end
    end

    # Returns the formula as a string. Will return an empty string if the formula is not set.
    def formula_string
      formula ? formula.fetch("formula", "") : ""
    end

    def formula_referenced_custom_field_ids
      formula ? formula.fetch("referenced_custom_fields", []) : []
    end

    def usable_custom_field_references_for_formula
      cache = {}

      ProjectCustomField
        .where(field_format: FIELD_FORMATS_FOR_FORMULA)
        .where.not(id:)
        .visible
        .select { it.can_be_referenced_by?(id, cache) }
    end

    def validate_referenced_custom_fields
      # We can only validate used custom fields from a high-level perspective, since at this point in validation,
      # we do not have a project context to check against. So we cannot check if the custom fields are actually
      # enabled for a project and visible to a non-admin user.
      formula_cfs = formula_referenced_custom_field_ids
      allowed_cfs = usable_custom_field_references_for_formula.pluck(:id)

      surplus_cfs = formula_cfs - allowed_cfs

      if surplus_cfs.any?
        names_by_id = CustomField.where(id: surplus_cfs).pluck(:id, :name).to_h
        custom_field_names = surplus_cfs.filter_map { names_by_id[it] }
        errors.add(:formula, :not_allowed_custom_fields_referenced, custom_fields: custom_field_names.join(", "))
      end
    end

    def can_be_referenced_by?(target_id, cache = {})
      return true unless field_format_calculated_value?

      cache.fetch(id) do
        cache[id] = false # assume it cannot be referenced until proven otherwise during recursion

        referenced_ids = formula_referenced_custom_field_ids

        cache[id] = !referenced_ids.intersect?([target_id, id]) &&
          ProjectCustomField.where(id: referenced_ids).all? { it.can_be_referenced_by?(target_id, cache) }
      end
    end

    # Returns `formula_string` with all custom field references detokenized so that they are parseable by Dentaku.
    # For example, for `2 + {{cf_12}} + {{cf_4}}` it returns `2 + cf_12 + cf_4`.
    def formula_str_without_patterns
      formula_string.gsub(/\{\{(cf_\d+)}}/, '\1')
    end

    private

    def valid_formula_syntax?
      # Attempt to parse the formula. If no error is returned, the formula is syntactically valid.
      CustomField::CalculatedValue.calculator_instance.ast(formula_str_without_patterns)
      true
    rescue Dentaku::ParseError, Dentaku::TokenizerError
      false
    end

    def formula_contains_only_allowed_tokens?
      # List of allowed characters in a formula. This only performs a very basic validation.
      # The allowed tokens are:
      # Operators, parentheses, comma, function names, whitespace, digits and decimal points.
      # Additionally, the formula may contain references to custom fields in the form of `{{cf_123}}`
      # where 123 is the ID of the custom field.
      # Once this basic validation passes, the formula will be parsed and validated by Dentaku, which builds an AST
      # and ensures that the formula is really valid.
      formula_string.split(FORMULA_SPLITTER).all?(FORMULA_TOKENS)
    end

    # Returns a list of custom field IDs used in the formula.
    # For a formula like `2 + {{cf_12}} + {{cf_4}}` it returns `[12, 4]`.
    def cf_ids_used_in_formula(formula_str)
      formula_str.scan(/(?<=\{\{cf_)\d+(?=}})/).map(&:to_i).uniq
    end
  end
end

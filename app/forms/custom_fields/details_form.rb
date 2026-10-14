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

module CustomFields
  class DetailsForm < ApplicationForm
    delegate :show_section_field?,
             :show_default_bool_field?,
             :show_default_text_field?,
             :show_default_rich_text_field?,
             :show_has_comment_field?,
             :show_is_required_field?,
             :show_min_max_length_field?,
             :show_min_max_value_field?,
             :show_regex_field?,
             :show_right_to_left_field?,
             :show_multi_value_field?,
             :show_formula_field?,
             :show_is_for_all_field?,
             :show_is_filter_field?,
             :show_is_searchable_field?,
             :show_non_open_versions_field?,
             :show_admin_only_field?,
             :show_editable_field?,
             :show_on_user_card_field?,
             to: :field_visibility

    form do |details_form|
      if model.new_record?
        details_form.hidden(
          name: :type,
          scope_name_to_model: false
        )

        details_form.hidden(
          name: :field_format
        )
      end

      details_form.text_field(
        name: :name,
        label: I18n.t(:label_name),
        required: true
      )

      if show_section_field?
        details_form.select_list(
          name: :custom_field_section_id,
          label: I18n.t("activerecord.attributes.project_custom_field.custom_field_section"),
          required: true
        ) do |list|
          section_class_for_model.all.each do |cs| # rubocop:disable Rails/FindEach -- ordered by default_scope; find_each would override it
            list.option(value: cs.id, label: cs.name)
          end
        end
      end

      if show_min_max_length_field?
        details_form.text_field(
          name: :min_length,
          type: :number,
          label: label(:min_length),
          caption: instructions(:min_max),
          input_width: :small
        )

        details_form.text_field(
          name: :max_length,
          type: :number,
          label: label(:max_length),
          caption: instructions(:min_max),
          input_width: :small
        )
      end

      if show_min_max_value_field?
        details_form.text_field(
          name: :min_value,
          type: :number,
          step: bound_step,
          value: model.min_bound,
          label: label(:min_value),
          caption: instructions(:min_max_value),
          input_width: :small
        )

        details_form.text_field(
          name: :max_value,
          type: :number,
          step: bound_step,
          value: model.max_bound,
          label: label(:max_value),
          caption: instructions(:min_max_value),
          input_width: :small
        )
      end

      if show_regex_field?
        details_form.text_field(
          name: :regexp,
          label: label(:regexp),
          caption: instructions(:regexp),
          input_width: :medium
        )
      end

      if show_formula_field?
        details_form.pattern_input(
          name: :formula,
          value: model.formula_string,
          suggestions: formula_suggestions,
          label: I18n.t(:label_formula),
          required: true,
          caption: instructions(:formula)
        )
      end

      if show_default_bool_field?
        details_form.check_box(
          name: :default_value,
          label: label(:default_value)
        )
      end

      if show_default_text_field?
        details_form.text_field(
          name: :default_value,
          label: label(:default_value),
          input_width: :medium
        )
      end

      if show_default_rich_text_field?
        details_form.rich_text_area(
          name: :default_value,
          label: label(:default_value),
          rich_text_options: { resource: nil, macros: :none }
        )
      end

      if show_multi_value_field?
        details_form.check_box(
          name: :multi_value,
          label: label(:multi_value),
          caption: instructions(:multi_select)
        )
      end

      if show_non_open_versions_field?
        details_form.check_box(
          name: :allow_non_open_versions,
          label: label(:allow_non_open_versions)
        )
      end

      if show_has_comment_field?
        details_form.check_box(
          name: :has_comment,
          label: label(:has_comment),
          caption: instructions(:has_comment)
        )
      end

      if show_is_required_field?
        details_form.check_box(
          name: :is_required,
          label: label(:is_required),
          caption: instructions(:is_required)
        )
      end

      if show_is_for_all_field?
        details_form.check_box(
          name: :is_for_all,
          label: label(:is_for_all),
          caption: instructions(:is_for_all)
        )
      end

      if show_is_filter_field?
        details_form.check_box(
          name: :is_filter,
          label: label(:is_filter),
          caption: instructions(:is_filter)
        )
      end

      if show_is_searchable_field?
        details_form.check_box(
          name: :searchable,
          label: label(:searchable),
          caption: instructions(:searchable)
        )
      end

      if show_right_to_left_field?
        details_form.check_box(
          name: :content_right_to_left,
          label: label(:content_right_to_left)
        )
      end

      if show_admin_only_field?
        details_form.check_box(
          name: :admin_only,
          label: label(:admin_only),
          caption: instructions(:admin_only)
        )
      end

      if show_editable_field?
        details_form.check_box(
          name: :editable,
          label: label(:editable),
          caption: instructions(:editable)
        )
      end

      if show_on_user_card_field?
        details_form.check_box(
          name: :visible_on_user_card,
          label: label(:visible_on_user_card),
          caption: instructions(:visible_on_user_card)
        )
      end

      details_form.submit(name: :submit, label: I18n.t(:button_save), scheme: :primary)
    end

    def field_visibility
      @field_visibility ||= DetailsFieldVisibility.new(model)
    end

    def label(field)
      I18n.t("activerecord.attributes.custom_field.#{field}")
    end

    def instructions(field)
      key = if model.is_a?(ProjectCustomField)
              "custom_fields.instructions.#{field}.project"
            else
              "custom_fields.instructions.#{field}.all"
            end

      I18n.t(key)
    end

    def section_class_for_model
      model.is_a?(UserCustomField) ? UserCustomFieldSection : ProjectCustomFieldSection
    end

    def bound_step
      model.field_format == "int" ? 1 : "any"
    end

    # Formula suggestions for operators, punctuation, functions and keywords are inserted as plain text
    # nodes instead of tokens, since displaying them as tokens would result in too much visual clutter.
    # We still want to offer autocompletion for them.
    FORMULA_OPERATOR_SUGGESTIONS = CustomField::CalculatedValue::FORMULA_OPERATORS
      # Hide % from the suggestions as it can be used as either modulo or percentage.
      .reject { it == "%" }
      .map { { key: it, label: it, insert_as_text: true, enabled: true } }
      .freeze

    FORMULA_PUNCTUATION_SUGGESTIONS = CustomField::CalculatedValue::FORMULA_PUNCTUATION
      .map { { key: it, label: it, insert_as_text: true, enabled: true } }
      .freeze

    # Insert functions with the opening parenthesis so that the caret ends up where the arguments go.
    FORMULA_FUNCTION_SUGGESTIONS = CustomField::CalculatedValue::FORMULA_FUNCTIONS
      .map { { key: "#{it}(", label: "#{it}()", insert_as_text: true, enabled: true } }
      .freeze

    FORMULA_KEYWORD_SUGGESTIONS = CustomField::CalculatedValue::FORMULA_KEYWORDS
      .map { { key: it, label: it, insert_as_text: true, enabled: true } }
      .freeze

    FORMULA_CONSTANT_SUGGESTIONS = CustomField::CalculatedValue::FORMULA_CONSTANTS
      .map { { key: it, label: it, insert_as_text: true, enabled: true } }
      .freeze

    private_constant :FORMULA_OPERATOR_SUGGESTIONS,
                     :FORMULA_PUNCTUATION_SUGGESTIONS,
                     :FORMULA_FUNCTION_SUGGESTIONS,
                     :FORMULA_KEYWORD_SUGGESTIONS,
                     :FORMULA_CONSTANT_SUGGESTIONS

    def formula_suggestions
      custom_fields = model.usable_custom_field_references_for_formula.map do |cf|
        { key: "cf_#{cf.id}", label: cf.name, enabled: true }
      end

      {
        custom_fields: { title: I18n.t("label_custom_field_plural"), tokens: custom_fields },
        operators: { title: I18n.t("label_operator_plural"), tokens: FORMULA_OPERATOR_SUGGESTIONS },
        punctuation: { title: I18n.t("label_punctuation"), tokens: FORMULA_PUNCTUATION_SUGGESTIONS },
        functions: { title: I18n.t("label_function_plural"), tokens: FORMULA_FUNCTION_SUGGESTIONS },
        keywords: { title: I18n.t("label_keyword_plural"), tokens: FORMULA_KEYWORD_SUGGESTIONS },
        constants: { title: I18n.t("label_constant_plural"), tokens: FORMULA_CONSTANT_SUGGESTIONS }
      }
    end
  end
end

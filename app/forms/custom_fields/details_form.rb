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

module CustomFields
  class DetailsForm < ApplicationForm
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
            list.option(value: cs.id, label: cs.name.presence || I18n.t("settings.user_custom_fields.label_untitled_section"))
          end
        end
      end

      if show_min_max_field?
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

      details_form.submit(name: :submit, label: I18n.t(:button_save), scheme: :default)
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

    def show_section_field?
      model.is_a?(ProjectCustomField) || model.is_a?(UserCustomField)
    end

    def section_class_for_model
      model.is_a?(UserCustomField) ? UserCustomFieldSection : ProjectCustomFieldSection
    end

    def show_default_bool_field?
      %w[bool].include?(model.field_format)
    end

    def show_default_text_field?
      %w[list bool date text user version hierarchy weighted_item_list calculated_value].exclude?(model.field_format)
    end

    def show_default_rich_text_field?
      %w[text].include?(model.field_format)
    end

    def show_has_comment_field?
      model.can_have_comment?
    end

    def show_is_required_field?
      %w[calculated_value bool].exclude?(model.field_format)
    end

    def show_min_max_field?
      %w[list bool date user version link hierarchy weighted_item_list calculated_value].exclude?(model.field_format)
    end

    def show_regex_field?
      %w[list bool date user version hierarchy weighted_item_list calculated_value].exclude?(model.field_format)
    end

    def show_right_to_left_field?
      model.is_a?(WorkPackageCustomField) && %w[text].include?(model.field_format)
    end

    def show_multi_value_field?
      model.multi_value_possible?
    end

    def show_formula_field?
      %w[calculated_value].include?(model.field_format)
    end

    def show_is_for_all_field?
      model.is_a?(WorkPackageCustomField) || model.is_a?(ProjectCustomField)
    end

    def show_is_filter_field?
      model.is_a?(WorkPackageCustomField)
    end

    def show_is_searchable_field?
      (model.is_a?(WorkPackageCustomField) || model.is_a?(ProjectCustomField)) &&
        %w[bool date float int user version hierarchy weighted_item_list calculated_value].exclude?(model.field_format)
    end

    def show_non_open_versions_field?
      %w[version].include?(model.field_format) && model.allow_non_open_versions_possible?
    end

    def show_admin_only_field?
      model.class.customized_class&.admin_only_custom_fields_allowed?
    end

    def show_editable_field?
      model.is_a?(UserCustomField)
    end

    def show_on_user_card_field?
      model.is_a?(UserCustomField)
    end

    def formula_suggestions
      operators = CustomField::CalculatedValue::MATH_OPERATORS_FOR_FORMULA
                    # Hide % from the suggestions as it can be used as either modulo or percentage.
                    .reject { it == "%" }
                    .map do |op|
        # Insert operators as plain text nodes instead of tokens, since displaying them as tokens would result
        # in too much visual clutter. We still want to offer autocompletion for them.
        { key: op, label: op, insert_as_text: true, enabled: true }
      end

      custom_fields = model.usable_custom_field_references_for_formula.map do |cf|
        { key: "cf_#{cf.id}", label: cf.name, enabled: true }
      end

      {
        custom_fields: { title: I18n.t("label_custom_field_plural"), tokens: custom_fields },
        operators: { title: I18n.t("label_mathematical_operators"), tokens: operators }
      }
    end
  end
end

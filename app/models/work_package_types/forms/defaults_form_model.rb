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

module WorkPackageTypes
  module Forms
    class DefaultsFormModel
      extend ActiveModel::Naming

      attr_reader :subject_configuration, :pattern, :default_work_package_description, :suggestions, :validation_errors

      # Built by both hosts of the defaults form: the edit tab and the creation wizard.
      # form_data carries the submitted values back after a failed validation.
      def self.build(variant, form_data: nil)
        values = form_values(variant, form_data)

        new(
          subject_configuration: values[:subject_configuration],
          pattern: values[:pattern],
          default_work_package_description: variant.default_work_package_description,
          suggestions: suggestions_for(variant),
          validation_errors: variant.errors
        )
      end

      # Translates the form's flat subject_configuration/pattern pair into the nested
      # patterns collection the variant stores. A manual configuration with an empty
      # blueprint drops the subject pattern entirely.
      def self.to_patterns(form_params)
        case form_params
        in { subject_configuration: "generated", pattern: String => blueprint }
          { subject: { blueprint:, enabled: true } }
        in { subject_configuration: "manual", pattern: String => blueprint } unless blueprint.empty?
          { subject: { blueprint:, enabled: false } }
        else
          nil
        end
      end

      def self.form_values(variant, form_data)
        return form_data if form_data.present?

        subject_pattern = variant.patterns.subject || WorkPackageTypes::Pattern.new(blueprint: "", enabled: false)

        {
          subject_configuration: subject_pattern.enabled ? :generated : :manual,
          pattern: subject_pattern.blueprint
        }
      end
      private_class_method :form_values

      def self.suggestions_for(variant)
        enabled, disabled = WorkPackageTypes::Patterns::TokenPropertyMapper.new.partitioned_tokens_for_type(variant)
        groups = empty_token_groups

        enabled.each { |token| add_token(groups, token, enabled: true) }
        disabled.each { |token| add_token(groups, token, enabled: false) }

        groups.each_value { |group| group[:tokens].sort_by! { |token| token[:label] } }
      end
      private_class_method :suggestions_for

      def self.empty_token_groups
        %i[work_package parent project].index_with do |context|
          { title: I18n.t("types.edit.defaults.token.context.#{context}"), tokens: [] }
        end
      end
      private_class_method :empty_token_groups

      def self.add_token(groups, token, enabled:)
        groups[token.context][:tokens] << token_to_hash(token, enabled:)
      end
      private_class_method :add_token

      def self.token_to_hash(token, enabled:)
        {
          key: token.key,
          label: token.label,
          label_with_context: token.label_with_context,
          enabled:
        }
      end
      private_class_method :token_to_hash

      # Wiring for the Stimulus controller that toggles the pattern input as the
      # subject configuration changes. Both hosts attach it to their form element.
      def stimulus_data
        {
          controller: "admin--subject-configuration",
          admin__subject_configuration_hide_pattern_input_value: subject_configuration == :manual
        }
      end

      def initialize(subject_configuration:, pattern:, suggestions:, default_work_package_description: nil, validation_errors: {})
        @subject_configuration = subject_configuration
        @pattern = pattern
        @default_work_package_description = default_work_package_description
        @suggestions = suggestions
        @validation_errors = validation_errors
      end
    end
  end
end

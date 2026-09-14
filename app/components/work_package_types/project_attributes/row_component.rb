# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module ProjectAttributes
    class RowComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      ASPECT = TypeVariant::PROJECT_ATTRIBUTES

      def initialize(variant:, project_custom_field:, linked: false, exclusion_state: nil)
        super()

        @variant = variant
        @project_custom_field = project_custom_field
        @linked = linked
        @exclusion_state = exclusion_state
      end

      private

      attr_reader :linked

      def wrapper_uniq_by
        @project_custom_field.id
      end

      def exclusion_toggle
        WorkPackageTypes::ExclusionToggleComponent.new(
          exclusions: @exclusion_state,
          element_key: @project_custom_field.attribute_name,
          label: t("types.edit.project_attributes.exclusions.attribute_label", attribute: @project_custom_field.name),
          aspect: ASPECT,
          off_label: t("types.edit.project_attributes.disabled"),
          test_selector: "toggle-variant-project-attribute-#{@project_custom_field.id}"
        )
      end

      def active_for_variant?
        @variant.project_custom_field_type_mappings.any? do |mapping|
          mapping.custom_field_id == @project_custom_field.id
        end
      end

      def toggle_path
        toggle_type_project_attributes_path(
          **@variant.path_args,
          project_custom_field_type_mapping: {
            variant_id: @variant.id,
            custom_field_id: @project_custom_field.id
          }
        )
      end

      def toggle_data_attributes
        {
          "turbo-method": :post,
          "turbo-stream": true,
          test_selector: "toggle-variant-project-attribute-#{@project_custom_field.id}"
        }
      end
    end
  end
end

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
    class IndexComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable

      ASPECT = TypeVariant::PROJECT_ATTRIBUTES

      def initialize(variant:, project_custom_field_sections:)
        super()

        @variant = variant
        @project_custom_field_sections = project_custom_field_sections
      end

      private

      def linked?
        OpenProject::FeatureDecisions.type_variants_active? && @variant.linked?(ASPECT)
      end

      def exclusion_state
        return @exclusion_state if defined?(@exclusion_state)

        @exclusion_state = linked? ? WorkPackageTypes::ExclusionState.for(@variant, ASPECT) : nil
      end

      def visible_sections
        return @project_custom_field_sections unless linked?

        result = []
        @project_custom_field_sections.each do |section, custom_fields|
          shown = custom_fields.select { |cf| show_in_linked_mode?(cf) }
          result << [section, shown] if shown.any?
        end
        result
      end

      def show_in_linked_mode?(custom_field)
        source_active_field_ids.include?(custom_field.id) &&
          !exclusion_state&.excluded_by_source?(custom_field.attribute_name)
      end

      def source_active_field_ids
        @source_active_field_ids ||=
          @variant.effective_source_for(ASPECT).own_project_custom_field_type_mappings.to_set(&:custom_field_id)
      end

      def wrapper_data_attributes
        {
          controller: "filter--filter-list",
          "filter--filter-list-clear-button-id-value": clear_button_id
        }
      end

      def clear_button_id
        "project-attributes-filter-clear-button"
      end
    end
  end
end

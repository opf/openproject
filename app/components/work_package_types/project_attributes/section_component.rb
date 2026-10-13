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
    class SectionComponent < ApplicationComponent
      include ApplicationHelper
      include OpPrimer::ComponentHelpers
      include OpTurbo::Streamable
      include WorkPackageTypes::VariantRoutes

      def initialize(variant:, project_custom_field_section:, project_custom_fields:, linked: false, exclusion_state: nil)
        super()

        @variant = variant
        @project_custom_field_section = project_custom_field_section
        @project_custom_fields = project_custom_fields
        @linked = linked
        @exclusion_state = exclusion_state
      end

      private

      attr_reader :linked, :exclusion_state

      def enable_all_path
        enable_all_of_section_variant_project_attributes_path(helpers.variant_scope_project, @variant, **section_params)
      end

      def disable_all_path
        disable_all_of_section_variant_project_attributes_path(helpers.variant_scope_project, @variant, **section_params)
      end

      def section_params
        { project_custom_field_type_mapping: { custom_field_section_id: @project_custom_field_section.id } }
      end

      def wrapper_uniq_by
        @project_custom_field_section.id
      end
    end
  end
end

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

      def initialize(type:, project_custom_field_section:, project_custom_fields:)
        super

        @type = type
        @project_custom_field_section = project_custom_field_section
        @project_custom_fields = project_custom_fields
      end

      private

      def enable_all_path
        enable_all_of_section_type_project_attributes_path(
          @type,
          project_custom_field_type_mapping: bulk_action_params
        )
      end

      def disable_all_path
        disable_all_of_section_type_project_attributes_path(
          @type,
          project_custom_field_type_mapping: bulk_action_params
        )
      end

      def bulk_action_params
        {
          type_id: @type.id,
          custom_field_section_id: @project_custom_field_section.id
        }
      end

      def wrapper_uniq_by
        @project_custom_field_section.id
      end
    end
  end
end

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

      def initialize(type:, project_custom_field_sections:, readonly: false)
        super

        @type = type
        @project_custom_field_sections = project_custom_field_sections
        @readonly = readonly
      end

      private

      def visible_sections
        return @project_custom_field_sections unless @readonly

        sections_with_active_fields
      end

      def sections_with_active_fields
        result = []

        @project_custom_field_sections.each do |section, custom_fields|
          active_fields = custom_fields.select { |cf| active_field_ids.include?(cf.id) }
          result << [section, active_fields] if active_fields.any?
        end

        result
      end

      def active_field_ids
        @active_field_ids ||= @type.project_custom_field_type_mappings.to_set(&:custom_field_id)
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

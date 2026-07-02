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

      def initialize(type:, project_custom_field_sections:)
        super

        @type = type
        @project_custom_field_sections = project_custom_field_sections
      end

      private

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

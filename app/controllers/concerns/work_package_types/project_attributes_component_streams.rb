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

module WorkPackageTypes::ProjectAttributesComponentStreams
  extend ActiveSupport::Concern

  included do
    def update_project_attribute_sections_via_turbo_stream(
      type: @type,
      project_custom_field_sections: @project_custom_field_sections
    )
      update_via_turbo_stream(
        component: ::WorkPackageTypes::ProjectAttributes::IndexComponent.new(
          type:,
          project_custom_field_sections:
        )
      )
    end
  end
end

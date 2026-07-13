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
  class ProjectAttributesTabController < BaseTabController
    include OpTurbo::ComponentStream
    include WorkPackageTypes::ProjectAttributesComponentStreams

    current_menu_item [:edit, :toggle, :enable_all_of_section, :disable_all_of_section] do
      :types
    end

    before_action :eager_load_project_custom_field_data
    before_action :set_project_custom_field_section, only: %i[enable_all_of_section disable_all_of_section]

    def edit; end

    def toggle
      call = ProjectCustomFieldTypeMappings::ToggleService
        .new(user: current_user)
        .call(project_custom_field_type_mapping_params)

      if call.success?
        render json: {}, status: :ok
      else
        render json: {}, status: :unprocessable_entity
      end
    end

    def enable_all_of_section
      bulk_update_section(:enable)
    end

    def disable_all_of_section
      bulk_update_section(:disable)
    end

    private

    def eager_load_project_custom_field_data
      @project_custom_field_sections =
        ProjectCustomFieldSection.grouped_in_order(ProjectCustomField.visible)
    end

    def set_project_custom_field_section
      @project_custom_field_section = ProjectCustomFieldSection.find(
        project_custom_field_type_mapping_params[:custom_field_section_id]
      )
    end

    def bulk_update_section(action)
      call = ProjectCustomFieldTypeMappings::BulkUpdateService
        .new(
          user: current_user,
          type: @type,
          project_custom_field_section: @project_custom_field_section
        )
        .call(action:)

      if call.success?
        eager_load_project_custom_field_data
        update_project_attribute_sections_via_turbo_stream
      else
        error_message = call.message.presence || I18n.t(:notice_unsuccessful_update)
        render_error_flash_message_via_turbo_stream(message: error_message)
      end

      respond_with_turbo_streams(status: call.success? ? :ok : :unprocessable_entity)
    end

    def project_custom_field_type_mapping_params
      permitted_params = params.expect(
        project_custom_field_type_mapping: %i[
          type_id
          custom_field_id
          custom_field_section_id
        ]
      ).to_h

      permitted_params[:value] = params.permit(:value)[:value] if params.key?(:value)

      permitted_params
    end
  end
end

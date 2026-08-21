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

    ASPECT = TypeVariant::PROJECT_ATTRIBUTES

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

    # Linked types have no own mappings to toggle, so a section's bulk enable/disable narrows the
    # link's excluded_elements instead; independent types toggle their own mappings as before.
    def enable_all_of_section
      linked? ? bulk_exclusion(ExcludedElements::RemoveService) : bulk_update_section(:enable)
    end

    def disable_all_of_section
      linked? ? bulk_exclusion(ExcludedElements::AddService) : bulk_update_section(:disable)
    end

    private

    def linked?
      @variant.linked?(ASPECT)
    end

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
          variant: @variant,
          project_custom_field_section: @project_custom_field_section
        )
        .call(action:)

      respond_to_bulk(call)
    end

    def bulk_exclusion(service_class)
      call = service_class
        .new(user: current_user, variant: @variant)
        .call(aspect: ASPECT, elements: section_element_keys)

      respond_to_bulk(call)
    end

    def section_element_keys
      source_active_ids = @variant.effective_source_for(ASPECT)
                                  .own_project_custom_field_type_mappings.pluck(:custom_field_id)
      @project_custom_field_section.custom_fields.where(id: source_active_ids).map(&:attribute_name)
    end

    def respond_to_bulk(call)
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
          variant_id
          custom_field_id
          custom_field_section_id
        ]
      ).to_h

      permitted_params[:value] = params.permit(:value)[:value] if params.key?(:value)

      permitted_params
    end
  end
end

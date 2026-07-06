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

module ProjectCustomFieldTypeMappings
  class BulkUpdateService < ::BaseServices::BaseCallable
    def initialize(user:, type:, project_custom_field_section:)
      super()
      @user = user
      @type = type
      @project_custom_field_section = project_custom_field_section
    end

    def perform
      service_call = validate_permissions
      service_call = perform_bulk_edit(service_call, params) if service_call.success?

      service_call
    end

    private

    def validate_permissions
      if @user.admin?
        ServiceResult.success
      else
        ServiceResult.failure(errors: { base: :error_unauthorized })
      end
    end

    def perform_bulk_edit(service_call, params)
      custom_field_ids = ProjectCustomField.custom_field_ids_in_section(@project_custom_field_section.id)

      case params[:action]
      when :enable
        enable_custom_fields(custom_field_ids)
      when :disable
        disable_custom_fields(custom_field_ids)
      else
        raise ArgumentError, "Unsupported bulk update action: #{params[:action]}"
      end

      service_call
    rescue StandardError => e
      service_call.success = false
      service_call.errors = e.message
      service_call
    end

    def enable_custom_fields(custom_field_ids)
      new_mapping_ids = custom_field_ids - existing_mappings(custom_field_ids)

      create_mappings(new_mapping_ids) if new_mapping_ids.any?
    end

    def disable_custom_fields(custom_field_ids)
      @type.project_custom_field_type_mappings
        .where(custom_field_id: custom_field_ids)
        .delete_all

      reset_associations
    end

    def existing_mappings(custom_field_ids)
      @type.project_custom_field_type_mappings
        .where(custom_field_id: custom_field_ids)
        .pluck(:custom_field_id)
    end

    def create_mappings(custom_field_ids)
      @type.project_custom_field_type_mappings
        .insert_all(
          custom_field_ids.map { |id| { custom_field_id: id } },
          unique_by: %i[type_id custom_field_id]
        )

      reset_associations
    end

    def reset_associations
      @type.project_custom_field_type_mappings.reset
      @type.project_custom_fields.reset
    end
  end
end

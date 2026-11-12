# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ProjectCustomFieldTypeMappings
  class BulkUpdateService < ::BaseServices::BaseCallable
    def initialize(user:, variant:, project_custom_field_section:)
      super()
      @user = user
      @variant = variant
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
      @variant.own_project_custom_field_type_mappings
        .where(custom_field_id: custom_field_ids)
        .delete_all

      reset_associations
    end

    def existing_mappings(custom_field_ids)
      @variant.own_project_custom_field_type_mappings
        .where(custom_field_id: custom_field_ids)
        .pluck(:custom_field_id)
    end

    def create_mappings(custom_field_ids)
      @variant.own_project_custom_field_type_mappings
        .insert_all(
          custom_field_ids.map { |id| { custom_field_id: id } },
          unique_by: %i[type_variant_id custom_field_id]
        )

      reset_associations
    end

    def reset_associations
      @variant.own_project_custom_field_type_mappings.reset
      @variant.project_custom_fields.reset
    end
  end
end

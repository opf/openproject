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

module ProjectCustomFieldProjectMappings
  class BulkUpdateService < ::BaseServices::BaseCallable
    def initialize(user:, project:, project_custom_field_section:)
      super()
      @user = user
      @project = project
      @project_custom_field_section = project_custom_field_section
    end

    def perform
      service_call = validate_permissions
      service_call = perform_bulk_edit(service_call, params) if service_call.success?

      service_call
    end

    private

    def validate_permissions
      if @user.allowed_in_project?(:select_project_custom_fields, @project)
        ServiceResult.success
      else
        ServiceResult.failure(errors: { base: :error_unauthorized })
      end
    end

    def perform_bulk_edit(service_call, params)
      action = params[:action]
      custom_field_ids = ProjectCustomField.toggleable_ids_in_project_settings(@project, @user, @project_custom_field_section.id)

      begin
        case action
        when :enable
          enable_custom_fields(custom_field_ids)
        when :disable
          disable_custom_fields(custom_field_ids)
        end
      rescue StandardError => e
        service_call.success = false
        service_call.errors = e.message
      end

      recalculate_values(custom_field_ids:) if service_call.success?

      service_call
    end

    def recalculate_values(custom_field_ids:)
      affected_cfs = @project.all_available_custom_fields.affected_calculated_fields(custom_field_ids)

      @project.calculate_custom_fields(affected_cfs)

      @project.save if @project.changed_for_autosave?
    end

    def enable_custom_fields(custom_field_ids)
      existing_mapping_ids = existing_mappings(custom_field_ids)
      new_mapping_ids = custom_field_ids - existing_mapping_ids

      create_mappings(new_mapping_ids) if new_mapping_ids.any?
    end

    def disable_custom_fields(custom_field_ids)
      @project.project_custom_field_project_mappings
        .where(custom_field_id: custom_field_ids)
        .delete_all

      reset_associations
    end

    def existing_mappings(custom_field_ids)
      @project.project_custom_field_project_mappings
        .where(custom_field_id: custom_field_ids)
        .pluck(:custom_field_id)
    end

    def create_mappings(custom_field_ids)
      @project.project_custom_field_project_mappings
        .insert_all(
          custom_field_ids.map { |id| { custom_field_id: id } },
          unique_by: %i[project_id custom_field_id]
        )

      reset_associations
    end

    def reset_associations
      @project.project_custom_field_project_mappings.reset
      @project.project_custom_fields.reset
    end
  end
end

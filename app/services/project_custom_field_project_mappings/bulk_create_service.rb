# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ProjectCustomFieldProjectMappings
  class BulkCreateService < ::BaseServices::BaseCallable
    def initialize(user:, project:, project_custom_field:)
      super()
      @user = user
      @project = project
      @project_custom_field = project_custom_field
    end

    def perform
      service_call = validate_permissions
      service_call = perform_bulk_create(service_call) if service_call.success?

      service_call
    end

    def validate_permissions
      if @user.allowed_in_project?(:select_project_custom_fields, [@project, *@project.children])
        ServiceResult.success
      else
        ServiceResult.failure(errors: { base: :error_unauthorized })
      end
    end

    def perform_bulk_create(service_call)
      project_children_ids = @project.children.pluck(:id)
      project_children_mapping_ids = project_children_ids - existing_project_mappings(project_children_ids)
      new_mapping_ids = [@project.id, *project_children_mapping_ids]
      create_mappings(new_mapping_ids) if new_mapping_ids.any?

      service_call
    rescue StandardError => e
      service_call.success = false
      service_call.errors = e.message
    end

    def existing_project_mappings(project_ids)
      ProjectCustomFieldProjectMapping.where(
        custom_field_id: @project_custom_field.id,
        project_id: project_ids
      ).pluck(:project_id)
    end

    def create_mappings(project_ids)
      new_mappings = project_ids.map do |id|
        { project_id: id, custom_field_id: @project_custom_field.id }
      end
      ProjectCustomFieldProjectMapping.insert_all(new_mappings)
    end
  end
end

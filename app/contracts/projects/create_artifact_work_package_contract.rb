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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Projects
  class CreateArtifactWorkPackageContract < ::BaseContract
    validate :validate_project_initiation_request_enabled
    validate :allowed_to_create_work_package
    validate :validate_work_package_type
    validate :validate_work_package_status
    validate :validate_assignee_custom_field

    def project = model

    protected

    def validate_project_initiation_request_enabled
      if !project.project_creation_wizard_enabled?
        add_error :base, :project_initiation_request_disabled
      end
    end

    def allowed_to_create_work_package
      return if user.allowed_in_project?(:add_work_packages, project)

      add_error :base, :error_unauthorized
    end

    def validate_work_package_type
      if project.project_creation_wizard_work_package_type_id.blank?
        add_error :project_creation_wizard_work_package_type_id, :blank
      elsif !project.project_creation_wizard_work_package_type_id.in?(project.type_ids)
        add_error :project_creation_wizard_work_package_type_id, :inclusion
      end
    end

    def validate_work_package_status
      if project.project_creation_wizard_status_when_submitted_id.blank?
        add_error :project_creation_wizard_status_when_submitted_id, :blank
      elsif invalid_status_for_type?
        add_error :project_creation_wizard_status_when_submitted_id, :inclusion
      end
    end

    def validate_assignee_custom_field
      return if project_assignee_custom_field_not_configured?

      if not_allowed_to_read_assignee_custom_field_value?
        add_error assignee_custom_field.attribute_name, :unauthorized
      elsif missing_assignee_custom_field_value?
        add_error assignee_custom_field.attribute_name, :blank
      elsif assignee_not_allowed_be_assigned_to_work_package?
        add_error assignee_custom_field.attribute_name, :cannot_be_assigned_to_artifact_work_package
      end
    end

    def project_assignee_custom_field_not_configured?
      project.project_creation_wizard_assignee_custom_field_id.blank?
    end

    def not_allowed_to_read_assignee_custom_field_value?
      # insufficient permissions to see the custom field value (current user is
      # not a member of the project or other reason)
      project.custom_value_for(assignee_custom_field).blank?
    end

    def missing_assignee_custom_field_value?
      assignee_id.blank?
    end

    def assignee_not_allowed_be_assigned_to_work_package?
      !Principal.possible_assignee(project).exists?(id: assignee_id)
    end

    def assignee_id
      project.custom_value_for(assignee_custom_field).value
    end

    def assignee_custom_field
      return @assignee_custom_field if defined?(@assignee_custom_field)

      @assignee_custom_field = project.available_custom_fields
                                      .find_by(id: project.project_creation_wizard_assignee_custom_field_id)
    end

    def invalid_status_for_type?
      type = Type.find_by(id: project.project_creation_wizard_work_package_type_id)
      return false if type.blank? # no extra error if there is already an error about type being blank

      type.statuses.pluck(:id).exclude?(project.project_creation_wizard_status_when_submitted_id)
    end

    def add_error(attribute, error)
      return if errors.added?(:base, :project_initiation_request_disabled)

      errors.add attribute, error
    end
  end
end

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

module Projects::Concerns
  module NewProjectService
    private

    def before_perform(params, service_call)
      super.tap do |super_call|
        reject_section_scoped_validation(super_call.result)
      end
    end

    def after_validate(params, service_call)
      super.tap do |super_call|
        build_missing_project_custom_field_project_mappings(super_call.result)
      end
    end

    def after_perform(attributes_call)
      new_project = attributes_call.result

      set_default_role(new_project) unless user.admin?
      disable_custom_fields_with_empty_values(new_project)
      notify_project_created(new_project)

      super
    end

    # Add default role to the newly created project
    # based on the setting ('new_project_user_role_id')
    # defined in the administration. Will either create a new membership
    # or add a role to an already existing one.
    def set_default_role(new_project)
      role = ProjectRole.in_new_project

      return unless role && new_project.persisted?

      # Assuming the members are loaded anyway
      user_member = new_project.members.detect { |m| m.principal == user }

      if user_member
        Members::UpdateService
          .new(user:, model: user_member, contract_class: EmptyContract)
          .call(role_ids: user_member.role_ids + [role.id])
      else
        Members::CreateService
          .new(user:, contract_class: EmptyContract)
          .call(roles: [role], project: new_project, principal: user)
      end
    end

    def notify_project_created(new_project)
      OpenProject::Notifications.send(
        OpenProject::Events::PROJECT_CREATED,
        project: new_project
      )
    end

    def reject_section_scoped_validation(new_project)
      if new_project._limit_custom_fields_validation_to_section_id.present?
        raise ArgumentError,
              "Section scoped validation is not supported for project creation, only for project updates"
      end
    end

    def disable_custom_fields_with_empty_values(new_project)
      # Ideally, `build_missing_project_custom_field_project_mappings` would not activate custom fields
      # with empty values, but:
      # This hook is required as acts_as_customizable build custom values with their default value
      # even if a blank value was provided in the project creation form.
      # `build_missing_project_custom_field_project_mappings` will then activate the custom field,
      # although the user explicitly provided a blank value. In order to not patch `acts_as_customizable`
      # further, we simply identify these custom values and deactivate the custom field.

      custom_field_ids = new_project.custom_values.select { |cv| cv.value.blank? && !cv.required? }.pluck(:custom_field_id)
      custom_field_project_mappings = new_project.project_custom_field_project_mappings

      custom_field_project_mappings
        .where(custom_field_id: custom_field_ids)
        .or(custom_field_project_mappings
          .where.not(custom_field_id: new_project.available_custom_fields.select(:id)))
        .destroy_all
    end

    def build_missing_project_custom_field_project_mappings(project)
      # Activate custom fields for this project (via mapping table) if values have been provided
      # for custom_fields, but no mapping exists.
      custom_field_ids = project.custom_values
        .select { |cv| cv.value.present? }
        .pluck(:custom_field_id).uniq
      activated_custom_field_ids = project.project_custom_field_project_mappings.pluck(:custom_field_id).uniq

      mappings = (custom_field_ids - activated_custom_field_ids).uniq
        .map { |custom_field_id| { custom_field_id: } }

      project.project_custom_field_project_mappings.build(mappings)
    end
  end
end

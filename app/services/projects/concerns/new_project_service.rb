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

module Projects::Concerns
  module NewProjectService
    private

    def before_perform(service_call)
      super.tap do |super_call|
        build_missing_project_custom_field_project_mappings(super_call.result)
      end
    end

    def after_persist(attributes_call)
      new_project = attributes_call.result

      set_default_role(new_project) unless user.admin?
      notify_project_created(new_project) if new_project.persisted?

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

      send_project_creation_email(new_project) if Setting.new_project_send_confirmation_email?
    end

    def send_project_creation_email(new_project)
      ProjectMailer.project_created(new_project, user:).deliver_later
    end

    def build_missing_project_custom_field_project_mappings(project)
      # Activate all custom fields (via mapping table) that have no mapping, but are either
      # intended for all projects, or have a value provided by the user.
      custom_field_ids = Set.new(activatable_custom_field_ids_from_project(project))
      custom_field_ids.merge(activatable_custom_field_ids_from_params)

      activated_custom_field_ids = project.project_custom_field_project_mappings.pluck(:custom_field_id).uniq

      mappings = (custom_field_ids - activated_custom_field_ids).uniq
        .map { |custom_field_id| { custom_field_id: } }

      project.project_custom_field_project_mappings.build(mappings)
    end

    def activatable_custom_field_ids_from_project(project)
      # We will activate fields with existing values, unless it's the default value, which might
      # be generated automatically
      project.custom_values
             .select { |cv| cv.is_for_all? || (cv.value? && !cv.default?) }
             .pluck(:custom_field_id)
    end

    def activatable_custom_field_ids_from_params
      # We will activate fields that are explicitly set via params

      # Extract custom field IDs from custom_field_values
      via_cf_values = params.fetch(:custom_field_values, {})
                            .keys
                            .map { it.to_s.to_i }

      # Extract custom field IDs from params keys that match 'custom_field_<id>'
      via_cf = params.keys
                     .grep(/\Acustom_field_\d+\z/)
                     .map { |k| k.to_s[/custom_field_(\d+)/, 1].to_i }

      via_cf_values + via_cf
    end

    def update_calculated_value_custom_fields(model)
      changed_cf_ids = model.custom_values.map(&:custom_field_id)

      # Using unscope(where: :admin_only) to fix an issue when non admin user
      # edits a custom field which is used by an admin only calculated value
      # field. Without this unscoping, admin only value and all fields
      # referencing it (recursively) will not be recalculated and there will
      # even be no place for that recalculation to be triggered unless an admin
      # edits same value again.
      #
      # This may need to be handled differently to make it work for other custom
      # field containers, like WorkPackage. User custom fields also has
      # admin_only check.
      affected_cfs = model.available_custom_fields.unscope(where: :admin_only).affected_calculated_fields(changed_cf_ids)

      model.calculate_custom_fields(affected_cfs)

      model.save if model.persisted? && model.changed_for_autosave?
    end
  end
end

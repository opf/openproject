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

module Projects::Concerns
  module ManageMembershipsFromCustomFields
    private

    def set_attributes(params)
      super.tap do |set_attributes_call|
        @custom_field_changes = set_attributes_call.result.custom_field_changes
      end
    end

    def after_perform(attributes_call)
      project = attributes_call.result

      assign_roles_for_user_custom_fields(project)

      super
    end

    def assign_roles_for_user_custom_fields(project) # rubocop:disable Metrics/AbcSize
      return unless project.persisted?
      return if @custom_field_changes.blank?
      return if project.available_custom_fields.user_field_with_assigned_role.none?

      user_fields_with_roles = project.available_custom_fields.user_field_with_assigned_role
      user_fields_with_roles.select do |cf|
        next unless @custom_field_changes.key?(cf.attribute_name)

        # turn values into arrays for easier handling
        old_value, new_value = @custom_field_changes[cf.attribute_name].map { Array.wrap(it) }

        Projects::ManageMembershipsFromCustomFieldsService
          .new(user: user, project: project, custom_field: cf)
          .call(old_value: old_value, new_value: new_value)
      end
    end
  end
end

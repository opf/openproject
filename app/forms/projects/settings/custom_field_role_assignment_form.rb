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
module Projects
  module Settings
    class CustomFieldRoleAssignmentForm < ApplicationForm
      form do |f|
        f.autocompleter(
          name: :role_id,
          label: I18n.t("custom_fields.admin.role_assignment.role_field_label"),
          caption: I18n.t("custom_fields.admin.role_assignment.role_field_caption"),
          autocomplete_options: {
            focusDirectly: true,
            inputValue: model.role_id,
            decorated: true,
            placeholder: I18n.t("label_none_parentheses"),
            hiddenFieldAction: "change->admin--custom-field-role-assignment#changeRole"
          }
        ) do |list|
          list.option(label: I18n.t("label_none_parentheses"), value: "", selected: model.role_id.nil?)

          assignable_roles.each do |role|
            list.option(label: role.name, value: role.id, selected: model.role_id.to_i == role.id)
          end
        end
      end

      private

      def assignable_roles
        ProjectRole.givable
      end
    end
  end
end

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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Roles
  class PermissionsDialogComponent < ApplicationComponent
    include OpTurbo::Streamable
    include OpPrimer::ComponentHelpers
    include RolesHelper

    TEST_SELECTOR = "op-roles--permissions-dialog"

    def self.visible_to?(user)
      user.admin? || user.allowed_in_any_project?(:manage_members)
    end

    alias_method :role, :model

    def dialog_id = dom_id(role, :permissions_dialog)

    def grouped_permissions
      @grouped_permissions ||= group_permissions_by_module(granted_permissions)
    end

    def module_title(mod)
      if mod.blank? && role.is_a?(GlobalRole)
        t(:label_global)
      else
        permission_header_for_project_module(mod)
      end
    end

    def module_list_id(mod)
      "#{dialog_id}-#{mod.presence || Project.model_name.param_key}"
    end

    def permission_label(permission) = t(:"permission_#{permission.name}")

    def permission_description(permission)
      t(:"permission_#{permission.name}_explanation", default: nil)
    end

    def implicit?(permission) = permission.public?

    def editable? = User.current.admin?

    private

    def granted_permissions
      OpenProject::AccessControl
        .permissions
        .select { |permission| granted?(permission) }
        .reject(&:hidden?)
    end

    def granted?(permission)
      return true if permission.public? && role.is_a?(ProjectRole)

      role.permissions.include?(permission.name)
    end
  end
end

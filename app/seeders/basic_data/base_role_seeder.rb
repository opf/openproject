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
module BasicData
  class BaseRoleSeeder < ModelSeeder
    self.needs = []

    def model_attributes(role_data)
      {
        type:,
        name: role_data["name"],
        position: role_data["position"],
        permissions: role_data["permissions"].uniq,
        builtin: builtin(role_data["builtin"])
      }
    end

    private

    def type
      model_class.to_s
    end

    def builtin(value)
      case value
      when :non_member then Role::BUILTIN_NON_MEMBER
      when :anonymous then Role::BUILTIN_ANONYMOUS
      when :work_package_editor then Role::BUILTIN_WORK_PACKAGE_EDITOR
      when :work_package_commenter then Role::BUILTIN_WORK_PACKAGE_COMMENTER
      when :work_package_viewer then Role::BUILTIN_WORK_PACKAGE_VIEWER
      when :project_query_view then Role::BUILTIN_PROJECT_QUERY_VIEW
      when :project_query_edit then Role::BUILTIN_PROJECT_QUERY_EDIT
      else Role::NON_BUILTIN
      end
    end

    def models_data
      super.each do |role_data|
        update_permissions_with_modules_data(role_data)
      end
    end

    def update_permissions_with_modules_data(role_data)
      role_reference, role_permissions = role_data.values_at("reference", "permissions")
      role_data["permissions"] =
        permissions(role_permissions) \
        + permissions_to_add(role_reference) \
        - permissions_to_remove(role_reference)
    end

    def permissions(value)
      case value
      when Array
        value
      when :all_assignable_permissions
        Roles::CreateContract.new(model_class.new, nil)
                             .assignable_permissions
                             .map(&:name)
      end
    end

    def permissions_to_add(role_reference)
      permission_changes_by_role.dig(role_reference, :add)
    end

    def permissions_to_remove(role_reference)
      permission_changes_by_role.dig(role_reference, :remove)
    end

    def permission_changes_by_role
      return @permission_changes_by_role if defined?(@permission_changes_by_role)

      @permission_changes_by_role = Hash.new { |h, role_reference| h[role_reference] = { add: [], remove: [] } }
      process_modules_permissions_data
      @permission_changes_by_role
    end

    def process_modules_permissions_data
      seed_data.each("modules_permissions") do |(_module, module_permissions_data)|
        module_permissions_data.each do |role_permissions_data|
          role_reference = role_permissions_data["role"]
          permission_changes = permission_changes_by_role[role_reference]
          permission_changes[:add].concat(Array(role_permissions_data["add"]))
          permission_changes[:remove].concat(Array(role_permissions_data["remove"]))
        end
      end
    end
  end
end

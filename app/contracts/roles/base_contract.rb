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

module Roles
  class BaseContract < ::ModelContract
    attribute :name

    validate :check_permission_prerequisites

    def assignable_permissions(keep_public: false)
      case model
      when GlobalRole
        assignable_global_permissions
      when WorkPackageRole
        assignable_work_package_permissions
      when ProjectQueryRole
        assignable_project_query_permissions
      else
        assignable_member_permissions
      end.reject do |permission|
        !keep_public && permission.public?
      end
    end

    private

    def assignable_global_permissions
      OpenProject::AccessControl.global_permissions
    end

    def assignable_work_package_permissions
      OpenProject::AccessControl.work_package_permissions
    end

    def assignable_project_query_permissions
      OpenProject::AccessControl.project_query_permissions
    end

    def assignable_member_permissions
      permissions_to_remove = case model.builtin
                              when Role::BUILTIN_NON_MEMBER
                                OpenProject::AccessControl.members_only_permissions
                              when Role::BUILTIN_ANONYMOUS
                                OpenProject::AccessControl.loggedin_only_permissions
                              else
                                []
                              end

      OpenProject::AccessControl.project_permissions - permissions_to_remove
    end

    def check_permission_prerequisites
      model.permissions.each do |name|
        permission = OpenProject::AccessControl.permission(name)

        next unless permission

        unmet_dependencies = permission.dependencies - model.permissions

        unmet_dependencies.each do |unmet_dependency|
          add_unmet_dependency_error(name, unmet_dependency)
        end
      end
    end

    def add_unmet_dependency_error(selected, unmet)
      errors.add(:permissions,
                 :dependency_missing,
                 permission: I18n.t("permission_#{selected}"),
                 dependency: I18n.t("permission_#{unmet}"))
    end
  end
end

#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'authorization'

Authorization.scope :principals do
  table :principals
  table :members
  table :member_roles
  table :roles
  table :projects
  table :enabled_modules

  scope_target principals

  condition :users_memberships, Authorization::Condition::UsersMemberships
  condition :member_roles_id_equal, Authorization::Condition::MemberRolesIdEqual
  condition :is_member, Authorization::Condition::IsMember
  condition :no_member, Authorization::Condition::NoMember
  condition :member_roles_role_id_equal, Authorization::Condition::MemberInProject
  condition :active_non_member_in_project, Authorization::Condition::ActiveNonMemberInProject
  condition :anonymous_in_project, Authorization::Condition::AnonymousInProject

  condition :enabled_modules_of_project, Authorization::Condition::EnabledModulesOfProject
  condition :always_false_unless_permission, Authorization::Condition::AlwaysFalse, if: ->(permission: nil, **ignored) { permission.nil? }
  condition :project_active, Authorization::Condition::ProjectActive
  condition :project_public, Authorization::Condition::PublicProject, if: ->(project: nil, **ignored) { project.present? }
  condition :projects_members, Authorization::Condition::ProjectsMembers
  condition :project_nil, Authorization::Condition::ProjectNil

  condition :permission_module_active, Authorization::Condition::PermissionsModuleActive

  condition :role_permitted, Authorization::Condition::RolePermitted
  condition :user_is_admin, Authorization::Condition::UserIsAdmin
  condition :any_role, Authorization::Condition::AnyRole
  condition :limit_to_project, Authorization::Condition::LimitToProject

  condition :member_in_project, member_roles_role_id_equal.and(is_member.and(project_active))
  condition :no_member_in_public_active_project, no_member.and(project_public)
  condition :member_in_inactive_project, is_member.and(project_nil)
  condition :fallback_project_condition, no_member_in_public_active_project.or(member_in_inactive_project)
  condition :fallback_role, fallback_project_condition.and(active_non_member_in_project.or(anonymous_in_project))
  condition :member_or_fallback, member_in_project.or(fallback_role)

  # this is a hacky optimisation that will prevent the enabled_modules table
  # from being loaded if no permission is queried for.  otherwise a lot more
  # rows will be returned which drastically increases the time required for
  # querying.
  condition :enabled_modules_or_nothing, enabled_modules_of_project.and(always_false_unless_permission)

  condition :permission_active, permission_module_active
  condition :permitted_in_project, permission_active.and(role_permitted)
  condition :permitted_role_for_project, member_or_fallback.and(permitted_in_project)

  condition :any_role_or_admin, any_role.or(user_is_admin)

  condition :project_join, (projects_members.or(project_public)).and(project_active.and(limit_to_project))

  condition :member_or_public_project, project_join

  principals.left_join(members)
            .on(users_memberships)
            .left_join(projects)
            .on(member_or_public_project)
            .left_join(enabled_modules)
            .on(enabled_modules_or_nothing)
            .left_join(member_roles)
            .on(member_roles_id_equal)
            .left_join(roles)
            .on(permitted_role_for_project)
            .where(any_role_or_admin)
end

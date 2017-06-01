#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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

class Authorization::ProjectQuery < Authorization::AbstractQuery
  self.model = Project

  def self.projects_members_join(user)
    projects_table[:id]
      .eq(members_table[:project_id])
      .and(members_table[:user_id].eq(user.id))
      .and(project_active_condition)
  end

  def self.enabled_modules_join(action)
    project_enabled_module_id_eq_condition
      .and(enabled_module_name_eq_condition(action))
      .and(project_active_condition)
  end

  def self.role_permissions_join
    permission_roles_table[:id]
      .eq(role_permissions_table[:role_id])
  end

  def self.project_enabled_module_id_eq_condition
    projects_table[:id]
      .eq(enabled_modules_table[:project_id])
  end

  def self.enabled_module_name_eq_condition(action)
    modules = action_project_modules(action)

    enabled_modules_table[:name].in(modules)
  end

  def self.project_active_condition
    projects_table[:status].eq(Project::STATUS_ACTIVE)
  end

  def self.members_member_roles_join
    members_table[:id].eq(member_roles_table[:member_id])
  end

  def self.roles_having_permissions(action)
    permissions_names = permissions(action).map(&:name)

    role_permissions_table[:permission].in(permissions_names)
  end

  def self.projects_table
    Project.arel_table
  end

  def self.enabled_modules_table
    EnabledModule.arel_table
  end

  def self.member_roles_table
    MemberRole.arel_table
  end

  def self.members_table
    Member.arel_table
  end

  def self.role_permissions_table
    RolePermission.arel_table
  end

  def self.permission_roles_table
    Role.arel_table.alias('permission_roles')
  end

  def self.assigned_roles_table
    Role.arel_table.alias('assigned_roles')
  end

  def self.role_has_permission_and_is_assigned(user, action)
    role_has_permission_condition(action)
      .and(project_active_condition)
      .and(assigned_roles_table[:id]
           .eq(member_roles_table[:role_id])
           .or(project_public_and_builtin_role_condition(user)))
  end

  def self.role_has_permission_condition(action)
    if action_public?(action)
      Arel::Nodes::Equality.new(1, 1)
    else
      assigned_roles_table[:id].eq(permission_roles_table[:id])
    end
  end

  def self.project_public_and_builtin_role_condition(user)
    builtin_role = if user.logged?
                     Role::BUILTIN_NON_MEMBER
                   else
                     Role::BUILTIN_ANONYMOUS
                   end

    projects_table[:is_public]
      .eq(true)
      .and(assigned_roles_table[:builtin].eq(builtin_role))
      .and(member_roles_table[:id].eq(nil))
  end

  def self.permissions(action)
    if action.is_a?(Hash)
      Redmine::AccessControl.allow_actions(action)
    else
      [Redmine::AccessControl.permission(action)].compact
    end
  end

  def self.action_project_modules(action)
    permissions(action).map(&:project_module).compact.uniq
  end

  def self.action_public?(action)
    permissions(action).all?(&:public?)
  end

  transformations.register :all,
                           :members_join do |statement, user|
    if user.admin?
      statement
    else
      statement
        .outer_join(members_table)
        .on(projects_members_join(user))
    end
  end

  transformations.register :all,
                           :enabled_modules_join,
                           after: [:members_join] do |statement, _, action|
    if action_project_modules(action).empty?
      statement
    else
      statement.join(enabled_modules_table)
               .on(enabled_modules_join(action))
    end
  end

  transformations.register :all,
                           :role_permissions_join,
                           after: [:enabled_modules_join] do |statement, user, action|
    if action_public?(action) || user.admin?
      statement
    else
      statement.join(role_permissions_table)
               .on(roles_having_permissions(action))
    end
  end

  transformations.register :all,
                           :members_member_roles_join,
                           after: [:members_join] do |statement, user|
    if user.admin?
      statement
    else
      statement.outer_join(member_roles_table)
               .on(members_member_roles_join)
    end
  end

  transformations.register :all,
                           :permission_roles_join,
                           after: [:role_permissions_join] do |statement, user, action|
    if action_public?(action) || user.admin?
      statement
    else
      statement.join(permission_roles_table)
               .on(role_permissions_join)
    end
  end

  transformations.register :all,
                           :assigned_roles_join,
                           after: [:permission_roles_join,
                                   :members_member_roles_join] do |statement, user, action|
    if user.admin?
      statement
    else
      statement.outer_join(assigned_roles_table)
               .on(role_has_permission_and_is_assigned(user, action))
    end
  end

  transformations.register :all,
                           :assigned_role_exists_condition do |statement, user|
    if user.admin?
      statement.where(project_active_condition)
    else
      statement.where(assigned_roles_table[:id].not_eq(nil))
    end
  end
end

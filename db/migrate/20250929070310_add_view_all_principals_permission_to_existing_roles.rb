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
require Rails.root.join("db/migrate/migration_utils/permission_adder")

class AddViewAllPrincipalsPermissionToExistingRoles < ActiveRecord::Migration[8.0]
  def up
    # Add global role "View all users (migration)"
    global_role_view_all_users

    # Add the view_all_users permission to this role
    unless global_role_view_all_users.has_permission?(:view_all_principals)
      global_role_view_all_users.add_permission!(:view_all_principals)
    end

    # Grant "View all users" permission to all global roles that currently have "Manage user" permission
    # This ensures Edit users has dependency on View users
    add_permission_to_manage_user_roles

    # For project roles with "manage_members", create a global role with "view_all_users"
    # and assign it to users who have those project roles
    add_global_role_for_manage_members
  end

  def down
    # Remove "View all users" permission from all global roles
    GlobalRole.joins(:role_permissions)
              .where(role_permissions: { permission: :view_all_principals })
              .find_each do |role|
      role.remove_permission!(:view_all_principals)
    end

    remove_global_role_members
    global_role_view_all_users.destroy
  end

  private

  def add_global_role_for_manage_members
    role_id = global_role_view_all_users.id

    find_user_ids_with_manage_members.each do |user_id|
      CallServiceJob.perform_later(
        "Members::AddRoleService",
        { user_id:, role_id:, project_id: nil, send_notifications: false },
        check_pending_migrations: true
      )
    end
  end

  def find_user_ids_with_manage_members
    project_roles_with_manage_members = ProjectRole.joins(:role_permissions)
                                                   .where(role_permissions: { permission: "manage_members" })
                                                   .distinct

    return [] if project_roles_with_manage_members.empty?

    # Find all users who have manage_members permission in any project
    # but avoid selecting PlaceholderUser
    Member.joins(:principal, member_roles: :role)
          .where(member_roles: { roles: { id: project_roles_with_manage_members.pluck(:id) } })
          .where.not("users.type": "PlaceholderUser")
          .pluck(:user_id)
          .uniq
  end

  def find_user_ids_with_view_all_users
    # Find all users who have manage_members permission in any project
    Member.joins(member_roles: :role)
          .where(project: nil, member_roles: { roles: { id: global_role_view_all_users.id } })
          .pluck(:user_id)
          .uniq
  end

  def remove_global_role_members
    service = Members::RemoveRoleService.new(current_user: User.system)

    find_user_ids_with_view_all_users.each do |user_id|
      service
        .call(user_id:, role_id: global_role_view_all_users.id, project_id: nil, send_notifications: false)
        .on_failure { |result| Rails.logger.error("Failed to remove global role from user #{user_id}: #{result.message}") }
    end
  end

  def global_role_view_all_users
    @global_role_view_all_users ||= GlobalRole.find_or_create_by(type: "GlobalRole", name: "View all users (migration)")
  end

  def add_permission_to_manage_user_roles
    ::Migration::MigrationUtils::PermissionAdder.add(:manage_user, :view_all_principals)
  end
end

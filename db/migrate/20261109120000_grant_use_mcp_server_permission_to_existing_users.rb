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

class GrantUseMcpServerPermissionToExistingUsers < ActiveRecord::Migration[8.0]
  def up
    # Only instances that already had the MCP server enabled had any users relying on
    # "any authenticated user can reach /mcp" - a fresh/never-configured instance has
    # nobody to preserve access for, so we leave the new permission unassigned there,
    # same as any other opt-in global permission.
    return unless McpConfiguration.server_config.enabled?

    global_role_mcp_access

    find_user_ids_to_grant_access.each do |user_id|
      CallServiceJob.perform_later(
        "Members::AddRoleService",
        { user_id:, role_id: global_role_mcp_access.id, project_id: nil, send_notifications: false },
        check_pending_migrations: true
      )
    end
  end

  def down
    remove_global_role_members
    global_role_mcp_access.destroy
  end

  private

  def global_role_mcp_access
    @global_role_mcp_access ||= begin
      role = GlobalRole.find_or_create_by(type: "GlobalRole", name: "MCP access (migration)")
      role.add_permission!(:use_mcp_server) unless role.has_permission?(:use_mcp_server)
      role
    end
  end

  def find_user_ids_to_grant_access
    # Same population that could reach /mcp before this migration: every real user
    # account, excluding placeholders/anonymous (neither of which can hold an OAuth
    # access token with the mcp scope in the first place).
    User.where(type: "User").pluck(:id)
  end

  def find_user_ids_with_mcp_access
    Member.joins(member_roles: :role)
          .where(project: nil, member_roles: { roles: { id: global_role_mcp_access.id } })
          .pluck(:user_id)
          .uniq
  end

  def remove_global_role_members
    service = Members::RemoveRoleService.new(current_user: User.system)

    find_user_ids_with_mcp_access.each do |user_id|
      service
        .call(user_id:, role_id: global_role_mcp_access.id, project_id: nil, send_notifications: false)
        .on_failure { |result| Rails.logger.error("Failed to remove global role from user #{user_id}: #{result.message}") }
    end
  end
end

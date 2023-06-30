# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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
# ++

module ActivePermissions::Updates::SqlIssuer
  using CoreExtensions::SquishSql

  UserProjectTouple = Data.define(:user_id, :project_id)

  # Select entries for all members in a project (public or private).
  def select_member_projects(condition = nil)
    <<~SQL.squish
      SELECT
        members.user_id user_id,
        projects.id project_id,
        permission_map.permission
      FROM members
      JOIN projects
        ON projects.id = members.project_id AND projects.active
      JOIN member_roles
        ON member_roles.member_id = members.id
      JOIN roles
        ON roles.id = member_roles.role_id
      LEFT JOIN role_permissions
        ON role_permissions.role_id = roles.id
      JOIN users
        ON users.id = members.user_id AND users.status != 3
      LEFT JOIN enabled_modules
        ON enabled_modules.project_id = projects.id
      JOIN (VALUES
        #{permission_map(global: false)}
      ) AS permission_map(permission, project_module_name, public, grant_admin, global)
        ON enabled_modules.name = permission_map.project_module_name OR permission_map.project_module_name IS NULL
      WHERE
        (role_permissions.permission = permission_map.permission OR permission_map.public)
      #{condition ? "AND #{condition}" : ''}
      GROUP BY
        members.user_id,
        projects.id,
        permission_map.permission
    SQL
  end

  # Select entries for all admins in a project (public or private)
  def select_admins_in_projects(condition = nil)
    <<~SQL.squish
      SELECT
        users.id user_id,
        projects.id project_id,
        permission_map.permission
      FROM projects
      JOIN users
        ON users.admin = true AND projects.active AND users.admin = true AND users.status != 3
      LEFT JOIN enabled_modules
        ON (enabled_modules.project_id = projects.id)
      JOIN
        (VALUES
          #{permission_map(grant_admin: true, global: false)}
        ) AS permission_map(permission, project_module_name, public, grant_admin, global)
        ON (enabled_modules.name = permission_map.project_module_name OR permission_map.project_module_name IS NULL)
      #{condition ? "WHERE #{condition}" : ''}
      GROUP BY users.id, projects.id, permission_map.permission
    SQL
  end

  # Select entries for all admins in a global context
  def select_admins_global(condition = nil)
    <<~SQL.squish
      SELECT
        users.id user_id,
        (NULL::bigint) project_id,
        permission_map.permission
      FROM
        (VALUES
          #{permission_map(grant_admin: true, global: true)}
        ) AS permission_map(permission, project_module_name, public, grant_admin, global),
        users
      WHERE
        permission_map.global
      AND
        users.admin = true
      AND
        users.status != 3
      #{condition ? "AND #{condition}" : ''}
      GROUP BY
        users.id,
        permission_map.permission
    SQL
  end

  # Select entries for all users in a global context based on a membership
  def select_member_global(condition = nil)
    <<~SQL.squish
      SELECT
        users.id user_id,
        (NULL::bigint) project_id,
        permission_map.permission
      FROM
        users,
        members,
        member_roles,
        roles,
        role_permissions,
        (VALUES
          #{permission_map(global: true)}
        ) AS permission_map(permission, project_module_name, public, grant_admin, global)
      WHERE
       (
         users.id = members.user_id
         AND members.project_id IS NULL
         AND members.id = member_roles.member_id
         AND member_roles.role_id = roles.id
         AND role_permissions.role_id = roles.id
         AND roles.type = 'GlobalRole'
         AND role_permissions.permission = permission_map.permission
       )
      AND
        users.status != 3
      #{condition ? "AND #{condition}" : ''}
      GROUP BY
        users.id,
        permission_map.permission
    SQL
  end

  def select_public_projects(condition = nil)
    <<~SQL.squish
      SELECT
        users.id user_id,
        projects.id project_id,
        permission_map.permission
      FROM projects
      LEFT JOIN enabled_modules
        ON enabled_modules.project_id = projects.id
      LEFT JOIN users
        ON users.status != 3
      LEFT JOIN roles
        ON (roles.builtin = #{Role::BUILTIN_NON_MEMBER} AND users.type IN ('User', 'PlaceholderUser'))
         OR (roles.builtin = #{Role::BUILTIN_ANONYMOUS} AND users.type IN ('AnonymousUser'))
      LEFT JOIN role_permissions
        ON role_permissions.role_id = roles.id
      LEFT JOIN (VALUES
        #{permission_map(grant_admin: true, global: false)}
      ) AS permission_map(permission, project_module_name, public, grant_admin, global)
        ON (enabled_modules.name = permission_map.project_module_name OR permission_map.project_module_name IS NULL)
         AND (role_permissions.permission = permission_map.permission OR permission_map.public)
      WHERE
        NOT EXISTS (SELECT 1 FROM members WHERE members.user_id = users.id AND members.project_id = projects.id)
      AND
        projects.active
      AND
        projects.public
      AND
        users.id IS NOT NULL
      AND
        projects.id IS NOT NULL
      AND
        permission_map.permission IS NOT NULL
      #{condition ? "AND #{condition}" : ''}
      GROUP BY
        users.id,
        projects.id,
        permission_map.permission
    SQL
  end

  def insert_active_permissions(select)
    connection.execute insert_active_permissions_sql(select)
  end

  def insert_active_permissions_sql(select)
    <<~SQL.squish
      INSERT INTO
        #{table_name} (user_id, project_id, permission)
      #{select}
      ON CONFLICT DO NOTHING
    SQL
  end

  def select_active_permissions(condition = nil)
    sql = <<~SQL.squish
      SELECT
        user_id user_id,
        project_id project_id,
        permission
      FROM
        #{table_name}
    SQL

    if condition.present?
      sql << " WHERE #{condition}"
    end
  end

  def user_project_condition
    "user_id IN (:user_id) AND project_id IN (:project_id)"
  end

  def table_name
    ActivePermission.table_name
  end

  private

  def permission_map(grant_admin: nil, global: nil)
    OpenProject::AccessControl
      .permissions
      .reject { |p| (!grant_admin.nil? && p.grant_to_admin? != grant_admin) || (!global.nil? && p.global? != global) }
      .map { |permission| permission_string(permission) }
      .join(', ')
  end

  def permission_string(permission)
    "('#{permission.name}',
       #{permission.project_module ? "'#{permission.project_module}'" : 'NULL'},
       #{permission.public?},
       #{permission.grant_to_admin?},
       #{permission.global?})"
  end

  delegate :sanitize,
           to: ::OpenProject::SqlSanitization

  delegate :connection,
           to: ActivePermission
end

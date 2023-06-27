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

class ActivePermission < ApplicationRecord
  using CoreExtensions::SquishSql

  belongs_to :user
  belongs_to :project

  class << self
    # TODO: only anonymous and actual users to be considered

    # Create entries for all members in a project (public or private).
    # TODO: move into transformation object
    def create_for_member_projects
      connection.execute <<~SQL.squish
        INSERT INTO
          #{table_name} (user_id, project_id, permission)
        SELECT
          members.user_id,
          projects.id,
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
        LEFT JOIN (VALUES
          #{permission_map(grant_admin: true, global: false)}
        ) AS permission_map(permission, project_module_name, public, grant_admin, global)
          ON enabled_modules.name = permission_map.project_module_name OR permission_map.project_module_name IS NULL
        WHERE
          (role_permissions.permission = permission_map.permission OR permission_map.public)
        ON CONFLICT DO NOTHING
      SQL
    end

    # Create entries for all admins in a project (public or private)
    # TODO: move into transformation object
    def create_for_admins_in_project
      connection.execute <<~SQL.squish
        INSERT INTO
          #{table_name} (user_id, project_id, permission)
        SELECT
          users.id,
          projects.id,
          permission_map.permission
        FROM
          projects,
          enabled_modules,
          (VALUES
            #{permission_map(grant_admin: true, global: false)}
          ) AS permission_map(permission, project_module_name, public, grant_admin, global),
          users
        WHERE
          (enabled_modules.project_id = projects.id OR permission_map.global)
        AND
          projects.active
        AND
          (enabled_modules.name = permission_map.project_module_name OR permission_map.project_module_name IS NULL)
        AND
          -- TODO: remove if the permission_map does not include any permissions not grantable to admins
          users.admin = true
        AND
          users.status != 3
        ON CONFLICT DO NOTHING
      SQL
    end

    # Create entries for all admins in a global context
    def create_for_admins_global
      connection.execute <<~SQL.squish
        INSERT INTO
          #{table_name} (user_id, project_id, permission)
        SELECT
          users.id,
          NULL,
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
        ON CONFLICT DO NOTHING
      SQL
    end

    # Create entries for all users in a global context based on a membership
    def create_for_member_global
      connection.execute <<~SQL.squish
        INSERT INTO
          #{table_name} (user_id, project_id, permission)
        SELECT
          users.id,
          NULL,
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
           AND role_permissions.permission = permission_map.permission
         )
        AND
          users.status != 3
        ON CONFLICT DO NOTHING
      SQL
    end

    def create_for_public_project
      connection.execute <<~SQL.squish
        INSERT INTO
          #{table_name} (user_id, project_id, permission)
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
        GROUP BY
          users.id,
          projects.id,
          permission_map.permission
        ON CONFLICT DO NOTHING
      SQL
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
  end
end

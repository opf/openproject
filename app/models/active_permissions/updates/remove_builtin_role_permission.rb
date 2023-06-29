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

class ActivePermissions::Updates::RemoveBuiltinRolePermission
  include ActivePermissions::Updates::SqlIssuer
  using CoreExtensions::SquishSql

  def initialize(role_permission)
    @permission = role_permission.permission
  end

  def execute
    sql = <<~SQL.squish
      WITH existing_permissions AS (
        SELECT
          user_id user_id,
          project_id project_id,
          permission
        FROM
          #{table_name}
        JOIN users
          ON users.id = #{table_name}.user_id
        JOIN projects
          ON projects.id = #{table_name}.project_id
        WHERE
          permission = :permission
        AND
          NOT users.admin
        AND
          projects.public
      ),
      current_permissions_member AS (
        #{select_member_projects('permission_map.permission = :permission AND projects.public')}
      ),
      current_permissions_public AS (
        #{select_public_projects('permission_map.permission = :permission')}
      )

      DELETE FROM
        #{table_name}
      WHERE
      EXISTS (
        SELECT
          1
        FROM
        (
          SELECT user_id, project_id, permission FROM existing_permissions
          EXCEPT
          SELECT user_id, project_id, permission FROM current_permissions_member
          EXCEPT
          SELECT user_id, project_id, permission FROM current_permissions_public
        ) to_delete
        WHERE
          to_delete.user_id = #{table_name}.user_id
        AND
          to_delete.project_id = #{table_name}.project_id
        AND
          to_delete.permission = #{table_name}.permission
      )
    SQL

    connection.execute(sanitize(sql, permission:))
  end

  private

  attr_reader :permission
end

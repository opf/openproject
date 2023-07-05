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

class ActivePermissions::Updates::RemoveByProjectPermission
  include ActivePermissions::Updates::SqlIssuer
  include ActivePermissions::Updates::MultipleUpdater
  using CoreExtensions::SquishSql

  def execute
    sql = <<~SQL.squish
      WITH existing_permissions AS (
        #{select_active_permissions('permission IN (:permission) AND project_id IS NOT NULL')}
      ),
      current_project_permissions AS (
        #{select_member_projects('permission_map.permission IN (:permission)')}
      ),
      current_public_project_permissions AS (
        #{select_public_projects('permission_map.permission IN (:permission)')}
      ),
      current_admin_permissions AS (
        #{select_admins_in_projects('permission_map.permission IN (:permission)')}
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
          SELECT user_id, project_id, permission FROM current_project_permissions
          EXCEPT
          SELECT user_id, project_id, permission FROM current_public_project_permissions
          EXCEPT
          SELECT user_id, project_id, permission FROM current_admin_permissions
        ) to_delete
        WHERE
          to_delete.user_id = #{table_name}.user_id
        AND
          NULLIF(to_delete.project_id, #{table_name}.project_id) IS NULL
        AND
          to_delete.permission = #{table_name}.permission
      )
    SQL

    connection.execute(sanitize(sql, permission: parameter))
  end
end

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

class ActivePermissions::Updates::Reinitialize
  include ActivePermissions::Updates::SqlIssuer

  using CoreExtensions::SquishSql

  def execute
    ActivePermission.delete_all

    connection.execute <<~SQL.squish
      WITH admin_permissions AS (
        #{select_admins_in_projects}
      ), system_permissions AS (
        #{select_public_projects}
      ), member_permissions AS (
        #{select_member_projects}
      ), admins_global_permissions AS (
        #{select_admins_global}
      ), global_member_permissions AS (
        #{select_member_global}
      )

      #{insert_active_permissions_sql('SELECT * FROM admin_permissions
                                             UNION
                                             SELECT * FROM system_permissions
                                             UNION
                                             SELECT * FROM member_permissions
                                             UNION
                                             SELECT * FROM admins_global_permissions
                                             UNION
                                             SELECT * FROM global_member_permissions')}
    SQL
  end
end

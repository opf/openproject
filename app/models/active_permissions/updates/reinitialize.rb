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

    create_for_member_projects
    create_for_member_global
    create_for_admins_global
    create_for_admins_in_project
    create_for_public_project

    # sql = <<~SQL.squish
    #   WITH delete_all AS (
    #     DELETE FROM active_permissions
    #   ), create_for_member_projects AS (
    #     #{insert_active_permissions_sql(select_member_projects)}
    #   ), create_for_admins_in_projects AS (
    #     #{insert_active_permissions_sql(select_admins_in_projects)}
    #   ), create_for_admins_global AS (
    #     #{insert_active_permissions_sql(select_admins_global)}
    #   ), create_for_member_global AS (
    #     #{insert_active_permissions_sql(select_member_global)}
    #   ), create_for_public_project AS (
    #     #{insert_active_permissions_sql(select_public_projects)}
    #   )

    #   SELECT 1;
    # SQL

    # connection.execute sql
  end

  private

  # Create entries for all members in a project (public or private).
  def create_for_member_projects
    insert_active_permissions(select_member_projects)
  end

  # Create entries for all admins in a project (public or private)
  def create_for_admins_in_project
    insert_active_permissions(select_admins_in_projects)
  end

  # Create entries for all admins in a global context
  def create_for_admins_global
    insert_active_permissions(select_admins_global)
  end

  # Create entries for all users in a global context based on a membership
  def create_for_member_global
    insert_active_permissions(select_member_global)
  end

  def create_for_public_project
    insert_active_permissions(select_public_projects)
  end
end

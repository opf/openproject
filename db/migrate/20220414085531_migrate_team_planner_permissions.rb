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

class MigrateTeamPlannerPermissions < ActiveRecord::Migration[6.1]
  def up
    # Add view_team_planner role if a role already has the view_work_packages permission
    execute <<~SQL.squish
      INSERT INTO
        role_permissions
        (role_id, permission, created_at, updated_at)
      SELECT
        role_permissions.role_id, 'view_team_planner', NOW(), NOW()
      FROM
        role_permissions
      GROUP BY role_permissions.role_id
      HAVING
        ARRAY_AGG(role_permissions.permission)::text[] @> ARRAY['view_work_packages']
      AND
        NOT ARRAY_AGG(role_permissions.permission)::text[] @> ARRAY['view_team_planner'];
    SQL

    # Add manage_team_planner if a role already has
    # the view_team_planner (which in turn means the view_work_packages permission),
    # add_work_packages, edit_work_packages, save_queries and manage_public_queries permission
    execute <<~SQL.squish
      INSERT INTO
        role_permissions
        (role_id, permission, created_at, updated_at)
      SELECT
        role_permissions.role_id, 'manage_team_planner', NOW(), NOW()
      FROM
        role_permissions
      GROUP BY role_permissions.role_id
      HAVING
        ARRAY_AGG(role_permissions.permission)::text[] @>
        ARRAY['view_work_packages', 'add_work_packages', 'edit_work_packages', 'save_queries', 'manage_public_queries']
      AND
        NOT ARRAY_AGG(role_permissions.permission)::text[] @> ARRAY['manage_team_planner']
    SQL
  end

  def down
    # Nothing to do
  end
end

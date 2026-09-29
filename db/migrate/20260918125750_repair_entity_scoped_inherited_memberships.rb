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

class RepairEntityScopedInheritedMemberships < ActiveRecord::Migration[8.1]
  def up
    remove_leaked_inherited_roles
    mirror_project_less_group_memberships
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  # Propagation used to match a group's users by project id alone, so memberships
  # sharing one (a global membership and a project list share, or a project
  # membership and a work package share) handed each other their roles.
  def remove_leaked_inherited_roles
    emptied_member_ids = []

    say_with_time "Remove inherited roles that leaked across membership scopes" do
      emptied_member_ids = execute(<<~SQL.squish).pluck("member_id")
        DELETE FROM member_roles
        WHERE id IN (
          SELECT member_roles.id
          FROM member_roles
          INNER JOIN members ON members.id = member_roles.member_id
          INNER JOIN member_roles sources ON sources.id = member_roles.inherited_from
          INNER JOIN members source_members ON source_members.id = sources.member_id
          WHERE members.project_id  IS DISTINCT FROM source_members.project_id
             OR members.entity_type IS DISTINCT FROM source_members.entity_type
             OR members.entity_id   IS DISTINCT FROM source_members.entity_id
        )
        RETURNING member_id
      SQL
    end

    drop_roleless_memberships(emptied_member_ids)
  end

  # A separate statement, as data modifying CTEs share one snapshot and would
  # not see the roles deleted above.
  def drop_roleless_memberships(member_ids)
    return if member_ids.empty?

    say_with_time "Drop memberships left without any role" do
      execute(<<~SQL.squish)
        DELETE FROM members
        WHERE id IN (#{member_ids.map(&:to_i).join(',')})
        AND NOT EXISTS (SELECT 1 FROM member_roles WHERE member_roles.member_id = members.id)
      SQL
    end
  end

  # Share creation narrowed the group's memberships by project id, which never
  # matches the project less ones, leaving the group's principals without them.
  def mirror_project_less_group_memberships
    say_with_time "Mirror project less group memberships onto the group's principals" do
      execute(<<~SQL.squish)
        #{group_principals_cte}
        INSERT INTO members (user_id, project_id, entity_type, entity_id, created_at, updated_at)
        SELECT DISTINCT group_principals.user_id, group_members.project_id,
                        group_members.entity_type, group_members.entity_id, NOW(), NOW()
        FROM members group_members
        INNER JOIN group_principals ON group_principals.group_id = group_members.user_id
        WHERE #{project_less_share}
        AND NOT EXISTS (
          SELECT 1 FROM members existing
          WHERE existing.user_id = group_principals.user_id
          AND existing.project_id  IS NOT DISTINCT FROM group_members.project_id
          AND existing.entity_type IS NOT DISTINCT FROM group_members.entity_type
          AND existing.entity_id   IS NOT DISTINCT FROM group_members.entity_id
        )
      SQL
    end

    say_with_time "Mirror the roles of those group memberships" do
      execute(<<~SQL.squish)
        #{group_principals_cte}
        INSERT INTO member_roles (member_id, role_id, inherited_from)
        SELECT principal_members.id, group_roles.role_id, group_roles.id
        FROM members group_members
        INNER JOIN group_principals ON group_principals.group_id = group_members.user_id
        INNER JOIN member_roles group_roles
          ON group_roles.member_id = group_members.id AND group_roles.inherited_from IS NULL
        INNER JOIN members principal_members
          ON principal_members.user_id = group_principals.user_id
          AND principal_members.project_id  IS NOT DISTINCT FROM group_members.project_id
          AND principal_members.entity_type IS NOT DISTINCT FROM group_members.entity_type
          AND principal_members.entity_id   IS NOT DISTINCT FROM group_members.entity_id
        WHERE #{project_less_share}
        AND NOT EXISTS (
          SELECT 1 FROM member_roles existing
          WHERE existing.member_id = principal_members.id
          AND existing.inherited_from = group_roles.id
        )
      SQL
    end
  end

  # Nested groups carry the memberships of every group above them.
  def group_principals_cte
    <<~SQL.squish
      WITH RECURSIVE group_principals AS (
        SELECT group_id, user_id FROM group_users
        UNION
        SELECT ancestors.group_id, nested.user_id
        FROM group_principals ancestors
        INNER JOIN group_users nested ON nested.group_id = ancestors.user_id
      )
    SQL
  end

  def project_less_share
    "group_members.project_id IS NULL AND group_members.entity_type IS NOT NULL"
  end
end

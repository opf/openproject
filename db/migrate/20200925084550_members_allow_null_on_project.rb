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

class MembersAllowNullOnProject < ActiveRecord::Migration[6.0]
  def change
    change_column_null :members, :project_id, true
    change_column_default :members, :project_id, from: 0, to: nil
    add_column :members, :updated_at, :timestamp, default: -> { "CURRENT_TIMESTAMP" }

    reversible do |rev|
      rev.up do
        add_updated_at_values
        migrate_principal_roles_data
      end

      rev.down do
        migrate_global_members_data
      end
    end

    change_column_null :members, :updated_at, false
    rename_column :members, :created_on, :created_at

    drop_table :principal_roles do |t|
      t.column :role_id, :integer, null: false, index: true
      t.column :principal_id, :integer, null: false, index: true
      t.timestamps
    end
  end

  private

  def add_updated_at_values
    execute <<~SQL.squish
      UPDATE
        members
      SET#{' '}
        updated_at = created_on
    SQL
  end

  def migrate_principal_roles_data
    fetch_principal_roles.each do |principal_id, records|
      member_id = insert_into_members(principal_id, records.first["created_at"], records.first["updated_at"])
      insert_into_member_roles(member_id, records.pluck("role_id"))
    end
  end

  def fetch_principal_roles
    select_all("SELECT * from principal_roles")
      .to_a
      .group_by { |r| r["principal_id"] }
  end

  def insert_into_members(principal_id, created_at, updated_at)
    member_id = select_all <<~SQL.squish
      INSERT INTO
        members(user_id, created_on, updated_at)
      VALUES (#{principal_id}, '#{created_at}', '#{updated_at}')
      RETURNING id
    SQL

    member_id.to_a.first["id"]
  end

  def insert_into_member_roles(member_id, role_ids)
    values = role_ids.map { |role_id| "(#{member_id}, #{role_id})" }

    execute <<~SQL.squish
      INSERT INTO
        member_roles(member_id, role_id)
      VALUES #{values.join(', ')}
    SQL
  end

  def migrate_global_members_data
    insert_into_principal_roles
    delete_global_members
  end

  def insert_into_principal_roles
    execute <<~SQL.squish
      INSERT INTO
        principal_roles (principal_id, role_id, created_at, updated_at)
      SELECT
        user_id,
        role_id,
        created_on,
        created_on
      FROM
        members
      JOIN
        member_roles
      ON
        members.id = member_roles.member_id
      WHERE
        members.project_id IS NULL
    SQL
  end

  def delete_global_members
    execute <<~SQL.squish
      DELETE
      FROM
        members
      WHERE
        project_id IS NULL
    SQL

    execute <<~SQL.squish
      DELETE
      FROM
        member_roles
      WHERE
        id IN (
          SELECT
            member_roles.id
          FROM
            member_roles
          LEFT JOIN
            members
          ON
            member_roles.member_id = members.id
          WHERE
            members.id IS NULL
        )
    SQL
  end
end

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

require_relative "migration_utils/utils"

class CreateCustomFieldSections < ActiveRecord::Migration[7.0]
  include ::Migration::Utils

  def up
    create_table :custom_field_sections do |t|
      t.integer :position
      t.string :name
      t.string :type # project or nil (-> work_package)

      t.timestamps
    end

    add_reference :custom_fields, :custom_field_section
    add_column :custom_fields, :position_in_custom_field_section, :integer, null: true

    create_and_assign_default_section
  end

  def down
    remove_reference :custom_fields, :custom_field_section
    remove_column :custom_fields, :position_in_custom_field_section
    drop_table :custom_field_sections
  end

  private

  def create_and_assign_default_section
    create_section_sql = <<~SQL.squish
      INSERT INTO "custom_field_sections" ("position", "name", "type", "created_at", "updated_at")
      VALUES (:position, :name, :type, :created_at, :updated_at)
      RETURNING "id"
    SQL

    now = Time.current

    insert_result =
      execute_sql create_section_sql, type: "ProjectCustomFieldSection", name: "Project attributes",
                                      position: 1, created_at: now, updated_at: now

    update_sql = <<~SQL.squish
      UPDATE "custom_fields"
      SET
        "position_in_custom_field_section" = "mapping"."new_position",
        "custom_field_section_id" = :section_id
      FROM (
        SELECT
         id,
         ROW_NUMBER() OVER (ORDER BY updated_at) AS new_position
        FROM "custom_fields"
        WHERE "custom_fields"."type" = 'ProjectCustomField'
      ) AS "mapping"
      WHERE "custom_fields"."id" = "mapping"."id";
    SQL

    execute_sql(update_sql, section_id: insert_result.first["id"])
  end
end

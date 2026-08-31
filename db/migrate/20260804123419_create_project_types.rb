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

class CreateProjectTypes < ActiveRecord::Migration[8.1]
  def up
    # Old installations of OpenProject used ProjectType
    drop_table :project_types, if_exists: true

    create_table :project_types do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :type, null: false, foreign_key: { to_table: :types, on_delete: :cascade }
      t.references :variant, null: true, foreign_key: { to_table: :types, on_delete: :nullify }

      t.timestamps
    end

    add_index :project_types, :project_id
    add_index :project_types, %i[project_id type_id], unique: true

    backfill_from_projects_types
  end

  def down
    drop_table :project_types
  end

  private

  def backfill_from_projects_types
    execute <<~SQL.squish
      INSERT INTO project_types (project_id, type_id, variant_id, created_at, updated_at)
      SELECT pt.project_id,
             COALESCE(t.parent_id, t.id),
             MIN(CASE WHEN t.parent_id IS NOT NULL THEN t.id END),
             NOW(),
             NOW()
      FROM projects_types pt
      JOIN types t ON t.id = pt.type_id
      GROUP BY pt.project_id, COALESCE(t.parent_id, t.id)
    SQL
  end
end

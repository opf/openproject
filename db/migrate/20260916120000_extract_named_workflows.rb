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

require Rails.root.join("db/migrate/migration_utils/utils")

class ExtractNamedWorkflows < ActiveRecord::Migration[8.1]
  include Migration::Utils

  def up # rubocop:disable Metrics/AbcSize
    rename_table :workflows, :workflows_status_transitions

    create_table :workflows do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    add_column :type_variants, :workflow_id, :bigint

    say_with_time "Create a workflow for each owning variant" do
      execute <<~SQL.squish
        UPDATE type_variants
        SET workflow_id = nextval('workflows_id_seq')
        WHERE workflows_source_id IS NULL
      SQL

      execute <<~SQL.squish
        INSERT INTO workflows (id, name, created_at, updated_at)
        SELECT v.workflow_id,
               CASE
                 WHEN v.is_default_variant THEN t.name
                 ELSE t.name || ': ' || v.variant_name
               END,
               NOW(),
               NOW()
        FROM type_variants v
        INNER JOIN types t ON t.id = v.type_id
        WHERE v.workflows_source_id IS NULL
      SQL
    end

    say_with_time "Point linked variants at the terminal owner's workflow" do
      execute <<~SQL.squish
        WITH RECURSIVE chain AS (
          SELECT id, workflow_id, ARRAY[id] AS path
          FROM type_variants
          WHERE workflows_source_id IS NULL
          UNION ALL
          SELECT v.id, c.workflow_id, c.path || v.id
          FROM type_variants v
          INNER JOIN chain c ON v.workflows_source_id = c.id
          WHERE NOT v.id = ANY(c.path)
        )
        UPDATE type_variants v
        SET workflow_id = c.workflow_id
        FROM chain c
        WHERE v.id = c.id
          AND v.workflow_id IS NULL
      SQL
    end

    say_with_time "Give remaining variants their own workflow" do
      execute <<~SQL.squish
        UPDATE type_variants
        SET workflow_id = nextval('workflows_id_seq')
        WHERE workflow_id IS NULL
      SQL

      execute <<~SQL.squish
        INSERT INTO workflows (id, name, created_at, updated_at)
        SELECT v.workflow_id,
               CASE
                 WHEN v.is_default_variant THEN t.name
                 ELSE t.name || ': ' || v.variant_name
               END,
               NOW(),
               NOW()
        FROM type_variants v
        INNER JOIN types t ON t.id = v.type_id
        WHERE NOT EXISTS (SELECT 1 FROM workflows w WHERE w.id = v.workflow_id)
      SQL
    end

    add_column :workflows_status_transitions, :workflow_id, :bigint

    execute <<~SQL.squish
      UPDATE workflows_status_transitions st
      SET workflow_id = v.workflow_id
      FROM type_variants v
      WHERE v.id = st.type_variant_id
    SQL

    change_column_null :workflows_status_transitions, :workflow_id, false
    add_index :workflows_status_transitions, :workflow_id
    add_foreign_key :workflows_status_transitions, :workflows, column: :workflow_id, on_delete: :cascade

    remove_index_on :workflows_status_transitions,
                    "wkfs_role_type_variant_old_status",
                    %w[role_id type_variant_id old_status_id]
    add_index :workflows_status_transitions,
              %i[role_id workflow_id old_status_id],
              name: "wkfs_role_workflow_old_status"

    remove_foreign_key :workflows_status_transitions, column: :type_variant_id
    remove_index :workflows_status_transitions, :type_variant_id
    remove_column :workflows_status_transitions, :type_variant_id

    change_column_null :type_variants, :workflow_id, false
    add_index :type_variants, :workflow_id
    add_foreign_key :type_variants, :workflows, column: :workflow_id, on_delete: :restrict
  end

  def down # rubocop:disable Metrics/AbcSize
    add_column :workflows_status_transitions, :type_variant_id, :bigint

    execute <<~SQL.squish
      UPDATE workflows_status_transitions st
      SET type_variant_id = owner.id
      FROM type_variants owner
      WHERE owner.workflow_id = st.workflow_id
        AND owner.workflows_source_id IS NULL
    SQL

    execute <<~SQL.squish
      DELETE FROM workflows_status_transitions
      WHERE type_variant_id IS NULL
    SQL

    change_column_null :workflows_status_transitions, :type_variant_id, false
    add_index :workflows_status_transitions, :type_variant_id
    add_foreign_key :workflows_status_transitions, :type_variants, column: :type_variant_id, on_delete: :cascade

    remove_index_on :workflows_status_transitions,
                    "wkfs_role_workflow_old_status",
                    %w[role_id workflow_id old_status_id]
    add_index :workflows_status_transitions,
              %i[role_id type_variant_id old_status_id],
              name: "wkfs_role_type_variant_old_status"

    remove_foreign_key :workflows_status_transitions, column: :workflow_id
    remove_index :workflows_status_transitions, :workflow_id
    remove_column :workflows_status_transitions, :workflow_id

    remove_foreign_key :type_variants, column: :workflow_id
    remove_index :type_variants, :workflow_id
    remove_column :type_variants, :workflow_id

    drop_table :workflows
    rename_table :workflows_status_transitions, :workflows
  end
end

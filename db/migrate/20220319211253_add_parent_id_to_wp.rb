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

class AddParentIdToWp < ActiveRecord::Migration[6.1]
  RELATION_TYPES = %i[relates duplicates blocks follows includes requires hierarchy].freeze

  def up
    migrate_parent_information

    add_relation_type

    add_relation_index

    add_closure_tree_table

    build_closure_tree

    cleanup_transitive_relations

    remove_typed_dag_columns
  end

  def down
    add_relation_type_column

    update_relation_column_from_relation_type

    insert_hierarchy_relation_for_parent

    remove_closure_tree

    remove_closure_tree_columns_on_foreign_tables

    build_typed_dag
  end

  private

  def migrate_parent_information
    add_column :work_packages, :parent_id, :integer, null: true

    add_parent_index

    execute <<~SQL.squish
      UPDATE
        work_packages
      SET
        parent_id = from_id
      FROM relations
      WHERE
        hierarchy = 1
        AND relates = 0
        AND duplicates = 0
        AND blocks = 0
        AND follows = 0
        AND includes = 0
        AND requires = 0
        AND work_packages.id = relations.to_id
    SQL

    execute <<~SQL.squish
      DELETE
      FROM
        relations
      WHERE
        hierarchy = 1
        AND #{(RELATION_TYPES - [:hierarchy]).join(' = 0 AND ')} = 0
    SQL
  end

  def add_relation_type
    add_column :relations, :relation_type, :string

    (RELATION_TYPES - [:hierarchy]).each do |type|
      execute <<~SQL.squish
        UPDATE
          relations
        SET
          relation_type = '#{type}'
        WHERE
          #{type} = 1
          AND #{(RELATION_TYPES - [type]).join(' = 0 AND ')} = 0
      SQL
    end
  end

  def add_closure_tree_table
    # Copied from closure tree migration
    create_table :work_package_hierarchies, id: false do |t|
      t.integer :ancestor_id, null: false
      t.integer :descendant_id, null: false
      t.integer :generations, null: false
    end

    add_index :work_package_hierarchies, %i[ancestor_id descendant_id generations],
              unique: true,
              name: "work_package_anc_desc_idx"

    add_index :work_package_hierarchies, [:descendant_id],
              name: "work_package_desc_idx"
    # End copied from closure tree migration
  end

  # Creates the actual closure tree data.
  # This recursive query is used over ClosureTreeWorkPackage.rebuild! for speed
  # but its result is equivalent.
  def build_closure_tree
    execute <<~SQL.squish
      WITH RECURSIVE closure_tree(ancestor_id, descendant_id, generations) AS (
      SELECT
        id ancestor_id,
        id descendant_id,
        0 generations
        FROM work_packages
      UNION
      SELECT
        closure_tree.ancestor_id,
        work_packages.id descendant_id,
        closure_tree.generations + 1
      FROM closure_tree
      JOIN work_packages ON work_packages.parent_id = closure_tree.descendant_id
      )

      INSERT INTO
        work_package_hierarchies (
          ancestor_id,
          descendant_id,
          generations
        )
      SELECT
        ancestor_id,
        descendant_id,
        generations
      FROM
        closure_tree
    SQL
  end

  def add_relation_index
    add_index :relations, %i[from_id to_id relation_type],
              unique: true
    add_index :relations, %i[to_id from_id relation_type],
              unique: true
  end

  def add_parent_index
    add_index :work_packages, :parent_id
  end

  def add_relation_type_column
    change_table :relations do |r|
      RELATION_TYPES.each do |column|
        r.column column, :integer, default: 0, null: false
      end
    end
  end

  def cleanup_transitive_relations
    execute <<~SQL.squish
      DELETE
      FROM
        relations
      WHERE
        #{RELATION_TYPES.join(' + ')} != 1
    SQL
  end

  def remove_typed_dag_columns
    RELATION_TYPES.each do |type|
      remove_column :relations, type
    end

    remove_column :relations, :count
  end

  def update_relation_column_from_relation_type
    ActiveRecord::Base.connection.execute <<-SQL.squish
      UPDATE
        relations
      SET
        relates =    CASE
                     WHEN relations.relation_type = 'relates'
                     THEN 1
                     ELSE 0
                     END,
        duplicates = CASE
                     WHEN relations.relation_type = 'duplicates'
                     THEN 1
                     ELSE 0
                     END,
        blocks =     CASE
                     WHEN relations.relation_type = 'blocks'
                     THEN 1
                     ELSE 0
                     END,
        follows =    CASE
                     WHEN relations.relation_type = 'precedes'
                     THEN 1
                     ELSE 0
                     END,
        includes =   CASE
                     WHEN relations.relation_type = 'includes'
                     THEN 1
                     ELSE 0
                     END,
        requires =   CASE
                     WHEN relations.relation_type = 'requires'
                     THEN 1
                     ELSE 0
                     END
    SQL
  end

  def remove_closure_tree
    drop_table :work_package_hierarchies
  end

  def remove_closure_tree_columns_on_foreign_tables
    remove_column :relations, :relation_type

    remove_column :work_packages, :parent_id
  end

  def build_typed_dag
    require_relative "20180105130053_rebuild_dag"

    ::RebuildDag.new.up
  end

  def insert_hierarchy_relation_for_parent
    ActiveRecord::Base.connection.execute <<-SQL.squish
      INSERT INTO relations
        (from_id, to_id, hierarchy)
      SELECT w1.id, w2.id, 1
      FROM work_packages w1
      JOIN work_packages w2
      ON w1.id = w2.parent_id
    SQL
  end

  # rubocop:disable Rails/ApplicationRecord
  class ClosureTreeWorkPackage < ActiveRecord::Base
    self.table_name = "work_packages"

    has_closure_tree
  end
  # rubocop:enable Rails/ApplicationRecord
end

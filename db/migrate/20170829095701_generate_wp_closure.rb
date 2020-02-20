#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

class GenerateWpClosure < ActiveRecord::Migration[5.0]
  def up
    add_relation_type_column

    update_relation_column_from_relation_type

    invert_from_to_on_follows("relation_type = 'precedes'")

    insert_hierarchy_relation_for_parent

    remove_column :relations, :relation_type

    remove_nested_set_columns
  end

  def down
    recreate_nested_set_columns

    invert_from_to_on_follows('follows = 1')

    set_parent_id

    remove_hierarchy_relations

    fill_relation_type_column

    remove_relation_type_specific_columns

    rebuild_nested_set
  end

  def relation_types
    %i(hierarchy relates duplicates blocks follows includes requires)
  end

  def add_relation_type_column
    change_table :relations do |r|
      relation_types.each do |column|
        r.column column, :integer, default: 0, null: false
      end
    end
  end

  def remove_nested_set_columns
    remove_column :work_packages, :parent_id
    remove_column :work_packages, :root_id
    remove_column :work_packages, :lft
    remove_column :work_packages, :rgt
  end

  def recreate_nested_set_columns
    add_column :work_packages, :parent_id, :integer
    add_column :work_packages, :root_id, :integer
    add_column :work_packages, :lft, :integer
    add_column :work_packages, :rgt, :integer

    add_index :work_packages, :parent_id
    add_index :work_packages, %i(root_id lft rgt)
  end

  def remove_hierarchy_relations
    ActiveRecord::Base.connection.execute <<-SQL
      DELETE FROM relations
      WHERE hierarchy > 0
    SQL
  end

  def invert_from_to_on_follows(condition)
    if ActiveRecord::Base.connection.adapter_name == 'Mysql2'
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE
         relations r1,
         relations r2
        SET
          r1.to_id = r1.from_id,
          r1.from_id = r2.to_id
        WHERE
          r1.id = r2.id
        AND
          r1.#{condition}
      SQL
    else
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE
          relations
        SET
          from_id = to_id,
          to_id = from_id
        WHERE
          #{condition}
      SQL
    end
  end

  def update_relation_column_from_relation_type
    ActiveRecord::Base.connection.execute <<-SQL
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

  def insert_hierarchy_relation_for_parent
    ActiveRecord::Base.connection.execute <<-SQL
      INSERT INTO relations
        (from_id, to_id, hierarchy)
      SELECT w1.id, w2.id, 1
      FROM work_packages w1
      JOIN work_packages w2
      ON w1.id = w2.parent_id
    SQL
  end

  def set_parent_id
    ActiveRecord::Base.connection.execute <<-SQL
      UPDATE
        work_packages
      SET
        parent_id =
          (SELECT from_id
          FROM relations
          WHERE to_id = work_packages.id
          AND relations.hierarchy = 1
          AND relations.relates = 0
          AND relations.duplicates = 0
          AND relations.blocks = 0
          AND relations.follows = 0
          AND relations.includes = 0
          AND relations.requires = 0)
    SQL
  end

  def fill_relation_type_column
    add_column :relations, :relation_type, :string

    ActiveRecord::Base.connection.execute <<-SQL
      UPDATE
        relations
      SET
        relation_type = CASE
                        WHEN relations.relates = 1
                        THEN 'relates'
                        WHEN relations.duplicates = 1
                        THEN 'duplicates'
                        WHEN relations.duplicates = 1
                        THEN 'blocks'
                        WHEN relations.follows = 1
                        THEN 'precedes'
                        WHEN relations.includes = 1
                        THEN 'includes'
                        WHEN relations.requires = 1
                        THEN 'requires'
                        END
    SQL
  end

  def remove_relation_type_specific_columns
    relation_types.each do |column|
      remove_column :relations, column
    end
  end

  def rebuild_nested_set
    NestedSetWorkPackage.rebuild_silently!
  end

  class NestedSetWorkPackage < ActiveRecord::Base
    self.table_name = 'work_packages'

    acts_as_nested_set scope: 'root_id', dependent: :destroy

    include OpenProject::NestedSet::RebuildPatch
  end
end

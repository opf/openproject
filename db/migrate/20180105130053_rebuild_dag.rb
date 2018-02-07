#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

class RebuildDag < ActiveRecord::Migration[5.0]
  def up
    truncate_closure_entries
    remove_duplicate_relations

    if index_exists?(:relations, relation_types)
      remove_index :relations, relation_types
    end

    add_column :relations, :count, :integer, default: 0, null: false

    set_count_to_1

    add_index :relations,
              %i(from_id to_id hierarchy relates duplicates blocks follows includes requires),
              name: 'index_relations_on_type_columns',
              unique: true

    WorkPackage.rebuild_dag! 1000

    add_count_index

    add_scheduling_indices

    add_non_hierarchy_index
  end

  def down
    remove_column :relations, :count

    remove_index :relations,
                 name: 'index_relations_hierarchy_follows_scheduling'
    remove_index :relations,
                 name: 'index_relations_only_hierarchy'
    remove_index :relations,
                 name: 'index_relations_to_from_only_follows'
    remove_index :relations,
                 name: 'index_relations_direct_non_hierarchy'

    truncate_closure_entries
  end

  private

  def add_count_index
    # supports finding relations that are to be deleted
    add_index :relations, :count, where: 'count = 0'
  end

  def add_scheduling_indices
    # supports relying on fast "Index Only Scan" for finding work packages that need to be rescheduled after a work package
    # has been moved
    add_index :relations,
              %i(to_id hierarchy follows from_id),
              name: 'index_relations_hierarchy_follows_scheduling',
              where: <<-SQL
                relations.relates = 0
                AND relations.duplicates = 0
                AND relations.blocks = 0
                AND relations.includes = 0
                AND relations.requires = 0
                AND (hierarchy + relates + duplicates + follows + blocks + includes + requires > 0)
              SQL

    add_index :relations,
              %i(from_id to_id hierarchy),
              name: 'index_relations_only_hierarchy',
              where: <<-SQL
                relations.relates = 0
                AND relations.duplicates = 0
                AND relations.follows = 0
                AND relations.blocks = 0
                AND relations.includes = 0
                AND relations.requires = 0
              SQL

    add_index :relations,
              %i(to_id follows from_id),
              name: 'index_relations_to_from_only_follows',
              where: <<-SQL
                hierarchy = 0
                AND relates = 0
                AND duplicates = 0
                AND blocks = 0
                AND includes = 0
                AND requires = 0
              SQL
  end

  def add_non_hierarchy_index
    # supports finding relations via the api as only non hierarchy relations are returned
    add_index :relations,
              :from_id,
              name: 'index_relations_direct_non_hierarchy',
              where: '(hierarchy + relates + duplicates + follows + blocks + includes + requires = 1) AND relations.hierarchy = 0'
  end

  def set_count_to_1
    ActiveRecord::Base.connection.execute <<-SQL
      UPDATE
        relations
      SET
        count = 1
    SQL
  end

  def truncate_closure_entries
    ActiveRecord::Base.connection.execute <<-SQL
      DELETE FROM relations
      WHERE (#{relation_types.join(' + ')} > 1)
      OR (#{relation_types.join(' + ')} = 0)
    SQL
  end

  def remove_duplicate_relations
    equal_conditions = relation_types.map do |type|
      "r1.#{type} = r2.#{type}"
    end.join(' AND ')

    ActiveRecord::Base.connection.execute <<-SQL
      DELETE
      FROM relations
      WHERE id IN (SELECT id FROM (SELECT r1.id
                                   FROM relations r1
                                   JOIN relations r2
                                   ON r1.id > r2.id
                                   AND r1.from_id = r2.from_id
                                   AND r1.to_id = r2.to_id
                                   AND #{equal_conditions}) delete_ids)
    SQL
  end

  def relation_types
    %i(hierarchy relates duplicates blocks follows includes requires)
  end
end

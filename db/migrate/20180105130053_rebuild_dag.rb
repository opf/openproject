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
    add_column :relations, :count, :integer, default: 0, null: false

    set_count_to_1

    if index_exists?(:relations, relation_types)
      remove_index :relations, relation_types
    end

    truncate_closure_entries

    add_index :relations,
              %i(from_id to_id hierarchy relates duplicates blocks follows includes requires),
              name: 'index_relations_on_type_columns',
              unique: true

    WorkPackage.rebuild_dag!

    # supports finding relations that are to be deleted
    add_index :relations, :count, where: 'count = 0'
  end

  def down
    remove_column :relations, :count

    truncate_closure_entries
  end

  private

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

  def relation_types
    %i(hierarchy relates duplicates blocks follows includes requires)
  end
end

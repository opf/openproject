#-- encoding: UTF-8
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

class JournalIndices < ActiveRecord::Migration[4.2]
  def up
    # remove existing indices on legacy_issues, if they still exist to avoid name-clashes with
    # the real(tm) journals-table
    if ActiveRecord::Base.connection.table_exists? :legacy_journals

      ActiveRecord::Base.connection.indexes(:legacy_journals).map(&:name).each do |index_name| remove_index :legacy_journals, name: index_name end

      add_index :legacy_journals, :activity_type, name: 'idx_lgcy_journals_on_activity_type'
      add_index :legacy_journals, :created_at, name: 'idx_lgcy_journals_on_created_at'
      add_index :legacy_journals, :journaled_id, name: 'idx_lgcy_journals_on_journaled_id'
      add_index :legacy_journals, :type, name: 'idx_lgcy_journals_on_type'
      add_index :legacy_journals, :user_id, name: 'idx_lgcy_journals_on_user_id'

    end

    add_index :journals, :journable_id
    add_index :journals, :created_at
    add_index :journals, :journable_type
    add_index :journals, :user_id
    add_index :journals, :activity_type
  end

  def down
    remove_index :journals, :journable_id
    remove_index :journals, :created_at
    remove_index :journals, :journable_type
    remove_index :journals, :user_id
    remove_index :journals, :activity_type
  end
end

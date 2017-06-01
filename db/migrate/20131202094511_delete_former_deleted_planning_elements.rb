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

require_relative 'migration_utils/utils'

class DeleteFormerDeletedPlanningElements < ActiveRecord::Migration[4.2]
  include Migration::Utils

  def up
    say_with_time_silently 'Remove deleted work packages and related journals' do
      delete_work_packages_marked_as_deleted
    end

    remove_column :work_packages, :deleted_at
    remove_column :work_package_journals, :deleted_at
  end

  def down
    add_column :work_packages, :deleted_at, :datetime
    add_column :work_package_journals, :deleted_at, :datetime
  end

  private

  def delete_work_packages_marked_as_deleted
    delete_ids_from_table('attachable_journals', 'journal_id', deleted_work_packages_journals_ids)
    delete_ids_from_table('customizable_journals', 'journal_id', deleted_work_packages_journals_ids)
    delete_ids_from_table('work_package_journals', 'journal_id', deleted_work_packages_journals_ids)
    delete_ids_from_table('journals', 'id', deleted_work_packages_journals_ids)
    delete_ids_from_table('work_packages', 'id', deleted_work_package_ids)
  end

  def delete_ids_from_table(table, id_column, ids)
    unless ids.empty?
      delete <<-SQL
        DELETE FROM #{table}
        WHERE #{id_column} IN (#{ids.join(', ')})
      SQL
    end
  end

  def deleted_work_package_ids
    return @deleted_work_package_ids if @deleted_work_package_ids

    result = select_all <<-SQL
      SELECT id FROM work_packages WHERE deleted_at IS NOT NULL
    SQL

    @deleted_work_package_ids = result.map { |r| r['id'] }
  end

  def deleted_work_packages_journals_ids
    return @deleted_work_packages_journals_ids if @deleted_work_packages_journals_ids

    result = select_all <<-SQL
      SELECT j.id
      FROM journals AS j
        JOIN work_packages AS w ON (j.journable_id = w.id AND j.journable_type = 'WorkPackage')
      WHERE w.deleted_at IS NOT NULL;
    SQL

    @deleted_work_packages_journals_ids = result.map { |r| r['id'] }
  end
end

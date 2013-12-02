#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require_relative 'migration_utils/utils'

class DeleteFormerDeletedPlanningElements < ActiveRecord::Migration
  include Migration::Utils

  def up
    say_with_time_silently "Remove deleted work packages and related journals" do
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
        WHERE #{id_column} IN (#{ids.join(", ")})
      SQL
    end
  end

  def deleted_work_package_ids
    return @deleted_work_package_ids if @deleted_work_package_ids

    result = select_all <<-SQL
      SELECT id FROM work_packages WHERE deleted_at IS NOT NULL
    SQL

    @deleted_work_package_ids = result.collect { |r| r['id'] }
  end

  def deleted_work_packages_journals_ids
    return @deleted_work_packages_journals_ids if @deleted_work_packages_journals_ids

    result = select_all <<-SQL
      SELECT j.id
      FROM journals AS j
        JOIN work_packages AS w ON (j.journable_id = w.id AND j.journable_type = 'WorkPackage')
      WHERE w.deleted_at IS NOT NULL;
    SQL

    @deleted_work_packages_journals_ids = result.collect { |r| r['id'] }
  end
end

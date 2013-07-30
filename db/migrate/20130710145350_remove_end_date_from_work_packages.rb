#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

class RemoveEndDateFromWorkPackages < ActiveRecord::Migration
  def up
    # This operation is destructive. The end dates of work packages will
    # be removed, updating due dates to the end date where due dates
    # were previously null. The down migration restores the end date
    # column from due_dates.
    execute <<-SQL
      UPDATE work_packages
        SET due_date = end_date
        WHERE due_date IS NULL;
    SQL
    remove_column :work_packages, :end_date
  end

  def down
    add_column :work_packages, :end_date, :date
    execute <<-SQL
      UPDATE work_packages
        SET end_date = due_date
        WHERE 1=1;
    SQL
  end
end

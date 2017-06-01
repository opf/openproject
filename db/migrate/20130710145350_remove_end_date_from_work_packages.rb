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

class RemoveEndDateFromWorkPackages < ActiveRecord::Migration[4.2]
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

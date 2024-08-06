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

class ConstrainWorkPackageDates < ActiveRecord::Migration[7.0]
  def change
    reversible do |dir|
      dir.up do
        WorkPackage.where("start_date > due_date").in_batches.each_record do |work_package|
          User.execute_as(User.system) do
            work_package.start_date = work_package.due_date
            work_package.duration = 1
            work_package.journal_notes = "_Resetting the start date automatically to fix inconsistent dates._"
            work_package.save!(validate: false)
          end
        end
      end
    end

    add_check_constraint :work_packages, "due_date >= start_date", name: "work_packages_due_larger_start_date"
  end
end

# frozen_string_literal: true

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

class AddDerivedRemainingHoursToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :derived_remaining_hours, :float
    add_column :work_package_journals, :derived_remaining_hours, :float

    reversible do |change|
      change.up do
        migrate_to_derived_remaining_hours!
      end

      change.down do
        rollback_from_derived_remaining_hours!
      end
    end
  end

  def work_packages_to_update
    WorkPackage.where.not(id: WorkPackage.leaves)
  end

  def migrate_to_derived_remaining_hours!
    scope = work_packages_to_update
              .where.not(remaining_hours: nil)
    scope.update_all("derived_remaining_hours = remaining_hours, remaining_hours = NULL")
  end

  def journal_user = SystemUser.first

  def rollback_from_derived_remaining_hours!
    scope = work_packages_to_update
              .where.not(derived_remaining_hours: nil)
    scope.update_all("remaining_hours = derived_remaining_hours")
  end
end

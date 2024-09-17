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

class WorkPackages::Progress::MigrateRemoveTotalsFromChildlessWorkPackagesJob < WorkPackages::Progress::Job
  include WorkPackages::Progress::SqlCommandsForMigration

  def perform
    updated_work_package_ids = remove_totals_from_childless_work_packages
    create_journals_for_updated_work_packages(updated_work_package_ids, cause: journal_cause)
  end

  private

  def journal_cause
    { type: "system_update", feature: "totals_removed_from_childless_work_packages" }
  end

  def remove_totals_from_childless_work_packages
    results = execute(<<~SQL.squish)
      UPDATE work_packages
      SET derived_estimated_hours = NULL,
          derived_remaining_hours = NULL,
          derived_done_ratio = NULL
      WHERE work_packages.id IN (
        SELECT ancestor_id AS id
        FROM work_package_hierarchies
        GROUP BY id
        HAVING MAX(generations) = 0
      )
      AND (
        work_packages.derived_estimated_hours IS NOT NULL
        OR work_packages.derived_remaining_hours IS NOT NULL
        OR work_packages.derived_done_ratio IS NOT NULL
      )
      RETURNING work_packages.id
    SQL
    results.column_values(0)
  end
end

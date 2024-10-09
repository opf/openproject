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

# Specific SQL commands for updating work package progress values during
# migrations, as some methods in `WorkPackages::Progress::SqlCommands` rely on
# fields that may not exist yet.
module WorkPackages::Progress::SqlCommandsForMigration
  def with_temporary_progress_table
    WorkPackage.transaction do
      create_temporary_progress_table
      yield
    ensure
      drop_temporary_progress_table
    end
  end

  # Create temporary tables with the columns that existed in version 14.0
  # (version where the migration is run).
  def create_temporary_progress_table
    execute(<<~SQL.squish)
      CREATE UNLOGGED TABLE temp_wp_progress_values
      AS SELECT
        id,
        status_id,
        estimated_hours,
        remaining_hours,
        done_ratio,
        NULL::double precision AS total_work,
        NULL::double precision AS total_remaining_work,
        NULL::integer AS total_p_complete
      FROM work_packages
    SQL
  end

  # Computes total work, total remaining work and total % complete for all work
  # packages having children.
  def update_totals
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET total_work = totals.total_work,
          total_remaining_work = totals.total_remaining_work,
          total_p_complete = CASE
            WHEN totals.total_work = 0 THEN NULL
            ELSE (1 - (totals.total_remaining_work / totals.total_work)) * 100
          END
      FROM (
        SELECT wp_tree.ancestor_id AS id,
               MAX(generations) AS generations,
               SUM(estimated_hours) AS total_work,
               SUM(remaining_hours) AS total_remaining_work
        FROM work_package_hierarchies wp_tree
          LEFT JOIN temp_wp_progress_values wp_progress ON wp_tree.descendant_id = wp_progress.id
        GROUP BY wp_tree.ancestor_id
      ) totals
      WHERE temp_wp_progress_values.id = totals.id
      AND totals.generations > 0
    SQL
  end
end

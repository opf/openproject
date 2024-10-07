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

module WorkPackages::Progress::SqlCommands
  def with_temporary_progress_table
    WorkPackage.transaction do
      create_temporary_progress_table
      create_temporary_depth_table
      yield
    ensure
      drop_temporary_depth_table
      drop_temporary_progress_table
    end
  end

  def create_temporary_progress_table
    execute(<<~SQL.squish)
      CREATE UNLOGGED TABLE temp_wp_progress_values
      AS SELECT
        work_packages.id,
        parent_id as parent_id,
        status_id,
        estimated_hours,
        remaining_hours,
        done_ratio,
        statuses.excluded_from_totals AS status_excluded_from_totals,
        NULL::double precision AS total_work,
        NULL::double precision AS total_remaining_work,
        NULL::integer AS total_p_complete
      FROM work_packages
      LEFT JOIN statuses ON work_packages.status_id = statuses.id
    SQL
  end

  def drop_temporary_progress_table
    execute(<<~SQL.squish)
      DROP TABLE temp_wp_progress_values
    SQL
  end

  def with_temporary_total_percent_complete_table
    WorkPackage.transaction do
      case mode
      when "work_weighted_average"
        create_temporary_total_percent_complete_table_for_work_weighted_average_mode
      when "simple_average"
        create_temporary_total_percent_complete_table_for_simple_average_mode
        create_temporary_depth_table
      else
        raise ArgumentError, "Invalid total percent complete mode: #{mode}"
      end

      yield
    ensure
      drop_temporary_total_percent_complete_table
      drop_temporary_depth_table
    end
  end

  def create_temporary_total_percent_complete_table_for_work_weighted_average_mode
    execute(<<~SQL.squish)
      CREATE UNLOGGED TABLE temp_wp_progress_values AS
      SELECT
        id,
        derived_estimated_hours as total_work,
        derived_remaining_hours as total_remaining_work,
        derived_done_ratio as total_p_complete
      FROM work_packages
    SQL
  end

  def create_temporary_total_percent_complete_table_for_simple_average_mode
    execute(<<~SQL.squish)
      CREATE UNLOGGED TABLE temp_wp_progress_values AS
      SELECT
        work_packages.id as id,
        work_packages.parent_id as parent_id,
        statuses.excluded_from_totals AS status_excluded_from_totals,
        done_ratio,
        NULL::INTEGER AS total_p_complete
      FROM work_packages
      LEFT JOIN statuses ON work_packages.status_id = statuses.id
    SQL
  end

  def create_temporary_depth_table
    execute(<<~SQL.squish)
      CREATE UNLOGGED TABLE temp_work_package_depth AS
      SELECT
        ancestor_id as id,
        max(generations) as depth
      FROM work_package_hierarchies
      GROUP BY ancestor_id
    SQL
  end

  def drop_temporary_total_percent_complete_table
    execute(<<~SQL.squish)
      DROP TABLE IF EXISTS temp_wp_progress_values
    SQL
  end

  def drop_temporary_depth_table
    execute(<<~SQL.squish)
      DROP TABLE IF EXISTS temp_work_package_depth
    SQL
  end

  def derive_remaining_work_from_work_and_percent_complete
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET remaining_hours =
        GREATEST(0,
          LEAST(estimated_hours,
            ROUND((estimated_hours - (estimated_hours * done_ratio / 100.0))::numeric, 2)
          )
        )
      WHERE estimated_hours IS NOT NULL
        AND done_ratio IS NOT NULL
    SQL
  end

  def set_percent_complete_from_status
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET done_ratio = statuses.default_done_ratio
      FROM statuses
      WHERE temp_wp_progress_values.status_id = statuses.id
    SQL
  end

  def fix_remaining_work_set_with_100_percent_complete
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET estimated_hours = remaining_hours,
          remaining_hours = 0
      WHERE estimated_hours IS NULL
        AND remaining_hours IS NOT NULL
        AND done_ratio = 100
    SQL
  end

  def derive_unset_work_from_remaining_work_and_percent_complete
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET estimated_hours =
        CASE done_ratio
          WHEN 0 THEN remaining_hours
          ELSE ROUND((remaining_hours * 100 / (100 - done_ratio))::numeric, 2)
        END
      WHERE estimated_hours IS NULL
        AND remaining_hours IS NOT NULL
        AND done_ratio IS NOT NULL
    SQL
  end

  # Computes total work, total remaining work and total % complete for all work
  # packages having children.
  def update_totals
    update_work_and_remaining_work_totals
    if Setting.total_percent_complete_mode == "work_weighted_average"
      update_total_percent_complete_in_work_weighted_average_mode
    elsif Setting.total_percent_complete_mode == "simple_average"
      update_total_percent_complete_in_simple_average_mode
    end
  end

  def update_work_and_remaining_work_totals
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET total_work = totals.total_work,
          total_remaining_work = totals.total_remaining_work
      FROM (
        SELECT wp_tree.ancestor_id AS id,
               SUM(estimated_hours) AS total_work,
               SUM(remaining_hours) AS total_remaining_work
        FROM work_package_hierarchies wp_tree
          LEFT JOIN temp_wp_progress_values wp_progress ON wp_tree.descendant_id = wp_progress.id
          LEFT JOIN statuses ON wp_progress.status_id = statuses.id
        WHERE statuses.excluded_from_totals = FALSE
        GROUP BY wp_tree.ancestor_id
      ) totals
      WHERE temp_wp_progress_values.id = totals.id
      AND temp_wp_progress_values.id IN (
        SELECT ancestor_id AS id
        FROM work_package_hierarchies
        GROUP BY id
        HAVING MAX(generations) > 0
      )
    SQL
  end

  def update_total_percent_complete_in_work_weighted_average_mode
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET total_p_complete = CASE
        WHEN total_work IS NULL OR total_remaining_work IS NULL THEN NULL
        WHEN total_work = 0 THEN NULL
        ELSE ROUND(
          ((total_work - total_remaining_work)::float / total_work) * 100
        )
      END
      WHERE id IN (
        SELECT ancestor_id
        FROM work_package_hierarchies
        GROUP BY ancestor_id
        HAVING MAX(generations) > 0
      )
    SQL
  end

  def update_total_percent_complete_in_simple_average_mode
    execute(<<~SQL.squish)
      DO $$
      DECLARE
        min_depth INTEGER := 0;
        max_depth INTEGER := (SELECT MAX(depth) FROM temp_work_package_depth);
        current_depth INTEGER := min_depth;
      BEGIN
        /* Navigate work packages and perform updates bottom-up */
        while current_depth <= max_depth loop
      UPDATE temp_wp_progress_values wp
      SET
        total_p_complete = CASE
          WHEN current_depth = min_depth THEN NULL
          ELSE ROUND(
            (
              /* Exclude the current work package if it has a status excluded from totals */
              CASE WHEN wp.status_excluded_from_totals
              THEN 0
              /* Otherwise, use the current work package's % complete value or 0 if unset */
              ELSE COALESCE(wp.done_ratio, 0)
              END + (
                SELECT
                  SUM(
                    COALESCE(child_wp.total_p_complete, child_wp.done_ratio, 0)
                  )
                FROM
                  temp_wp_progress_values child_wp
                WHERE
                  child_wp.parent_id = wp.id
                  /* Exclude children with a status excluded from totals */
                  AND NOT child_wp.status_excluded_from_totals
              )
              ) / (
              /* Exclude the current work package if it has a status excluded from totals */
              CASE WHEN wp.status_excluded_from_totals
              THEN 0
              /* Otherwise, count the current work package if it has a % complete value set */
              ELSE(CASE WHEN wp.done_ratio IS NOT NULL THEN 1 ELSE 0 END)
              END + (
                SELECT
                  COUNT(1)
                FROM
                  temp_wp_progress_values child_wp
                WHERE
                  child_wp.parent_id = wp.id
                  /* Exclude children with a status excluded from totals */
                  AND NOT child_wp.status_excluded_from_totals
              )
            )
          )
        END
      /* Select only work packages at the curren depth */
      WHERE
        wp.id IN (
          SELECT
            id
          FROM
            temp_work_package_depth
          WHERE
            depth = current_depth
        );

      /* Go up a level from a child to a parent*/
      current_depth := current_depth + 1;

      END loop;
      END $$;
    SQL
  end

  def copy_progress_values_to_work_packages_and_update_journals(cause)
    updated_work_package_ids = copy_progress_values_to_work_packages
    create_journals_for_updated_work_packages(updated_work_package_ids, cause:)
  end

  def copy_progress_values_to_work_packages
    results = execute(<<~SQL.squish)
      UPDATE work_packages
      SET estimated_hours = temp_wp_progress_values.estimated_hours,
          remaining_hours = temp_wp_progress_values.remaining_hours,
          done_ratio = temp_wp_progress_values.done_ratio,
          derived_estimated_hours = temp_wp_progress_values.total_work,
          derived_remaining_hours = temp_wp_progress_values.total_remaining_work,
          derived_done_ratio = temp_wp_progress_values.total_p_complete,
          lock_version = lock_version + 1,
          updated_at = NOW()
      FROM temp_wp_progress_values
      WHERE work_packages.id = temp_wp_progress_values.id
        AND (
          work_packages.estimated_hours IS DISTINCT FROM temp_wp_progress_values.estimated_hours
          OR work_packages.remaining_hours IS DISTINCT FROM temp_wp_progress_values.remaining_hours
          OR work_packages.done_ratio IS DISTINCT FROM temp_wp_progress_values.done_ratio
          OR work_packages.derived_estimated_hours IS DISTINCT FROM temp_wp_progress_values.total_work
          OR work_packages.derived_remaining_hours IS DISTINCT FROM temp_wp_progress_values.total_remaining_work
          OR work_packages.derived_done_ratio IS DISTINCT FROM temp_wp_progress_values.total_p_complete
        )
      RETURNING work_packages.id
    SQL
    results.column_values(0)
  end

  def copy_total_percent_complete_values_to_work_packages_and_update_journals(cause)
    updated_work_package_ids = copy_total_percent_complete_values_to_work_packages
    create_journals_for_updated_work_packages(updated_work_package_ids, cause:)
  end

  def copy_total_percent_complete_values_to_work_packages
    results = execute(<<~SQL.squish)
      UPDATE work_packages
      SET derived_done_ratio = temp_wp_progress_values.total_p_complete,
          lock_version       = lock_version + 1,
          updated_at         = NOW()
      FROM temp_wp_progress_values
      WHERE work_packages.id = temp_wp_progress_values.id
        AND (
          work_packages.derived_done_ratio IS DISTINCT FROM temp_wp_progress_values.total_p_complete
        )
      RETURNING work_packages.id
    SQL

    results.column_values(0)
  end

  def create_journals_for_updated_work_packages(updated_work_package_ids, cause:)
    WorkPackage.where(id: updated_work_package_ids).find_each do |work_package|
      Journals::CreateService
        .new(work_package, system_user)
        .call(cause:)
    end
  end

  # Executes an sql statement, shorter.
  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

  def system_user
    @system_user ||= User.system
  end
end

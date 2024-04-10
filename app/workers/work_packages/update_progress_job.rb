#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

# rubocop:disable Rails/SquishedSQLHeredocs
class WorkPackages::UpdateProgressJob < ApplicationJob
  queue_with_priority :default

  def perform(current_mode:, previous_mode:)
    with_temporary_progress_table do
      case current_mode
      when "field"
        unset_all_percent_complete_values if previous_mode == "disabled"
        fix_remaining_work_set_with_100p_complete
        fix_remaining_work_exceeding_work
        fix_only_work_being_set
        fix_only_remaining_work_being_set
        derive_unset_remaining_work_from_work_and_p_complete
        derive_unset_work_from_remaining_work_and_p_complete
        derive_p_complete_from_work_and_remaining_work
      when "status"
        set_p_complete_from_status
        fix_remaining_work_set_with_100p_complete
        derive_unset_work_from_remaining_work_and_p_complete
        derive_remaining_work_from_work_and_p_complete
      else
        raise "Unknown progress calculation mode: #{current_mode}, aborting."
      end

      update_totals

      copy_progress_values_to_work_packages_and_update_journals
    end
  end

  private

  def with_temporary_progress_table
    create_temporary_progress_table
    yield
  ensure
    drop_temporary_progress_table
  end

  def create_temporary_progress_table
    execute(<<~SQL)
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

  def drop_temporary_progress_table
    execute(<<~SQL)
      DROP TABLE temp_wp_progress_values
    SQL
  end

  def unset_all_percent_complete_values
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET done_ratio = NULL
      WHERE done_ratio IS NOT NULL
    SQL
  end

  def fix_remaining_work_set_with_100p_complete
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET estimated_hours = remaining_hours,
          remaining_hours = 0
      WHERE estimated_hours IS NULL
        AND remaining_hours IS NOT NULL
        AND done_ratio = 100
    SQL
  end

  def fix_remaining_work_exceeding_work
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET remaining_hours = CASE
          WHEN done_ratio IS NULL THEN estimated_hours
          ELSE ROUND((estimated_hours - (estimated_hours * done_ratio / 100.0))::numeric, 2)
        END
      WHERE remaining_hours > estimated_hours
    SQL
  end

  def fix_only_work_being_set
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET remaining_hours = estimated_hours
      WHERE estimated_hours IS NOT NULL
        AND remaining_hours IS NULL
        AND done_ratio IS NULL
    SQL
  end

  def fix_only_remaining_work_being_set
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET estimated_hours = remaining_hours
      WHERE estimated_hours IS NULL
        AND remaining_hours IS NOT NULL
        AND done_ratio IS NULL
    SQL
  end

  def derive_unset_remaining_work_from_work_and_p_complete
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET remaining_hours = ROUND((estimated_hours - (estimated_hours * done_ratio / 100.0))::numeric, 2)
      WHERE estimated_hours IS NOT NULL
        AND remaining_hours IS NULL
        AND done_ratio IS NOT NULL
    SQL
  end

  def derive_remaining_work_from_work_and_p_complete
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET remaining_hours = ROUND((estimated_hours - (estimated_hours * done_ratio / 100.0))::numeric, 2)
      WHERE estimated_hours IS NOT NULL
        AND done_ratio IS NOT NULL
    SQL
  end

  def derive_unset_work_from_remaining_work_and_p_complete
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET estimated_hours = ROUND((remaining_hours * 100 / (100 - done_ratio))::numeric, 2)
      WHERE estimated_hours IS NULL
        AND remaining_hours IS NOT NULL
        AND done_ratio IS NOT NULL
    SQL
  end

  def derive_p_complete_from_work_and_remaining_work
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET done_ratio = CASE
          WHEN estimated_hours = 0 THEN NULL
          ELSE (estimated_hours - remaining_hours) * 100 / estimated_hours
        END
      WHERE estimated_hours >= 0
        AND remaining_hours >= 0
    SQL
  end

  def set_p_complete_from_status
    execute(<<~SQL.squish)
      UPDATE temp_wp_progress_values
      SET done_ratio = statuses.default_done_ratio
      FROM statuses
      WHERE temp_wp_progress_values.status_id = statuses.id
    SQL
  end

  def update_totals
    execute(<<~SQL)
      UPDATE temp_wp_progress_values
      SET total_work = totals.total_work,
          total_remaining_work = totals.total_remaining_work,
          total_p_complete = CASE
            WHEN totals.total_work = 0 THEN NULL
            ELSE (1 - (totals.total_remaining_work / totals.total_work)) * 100
          END
      FROM (
        SELECT wp_tree.ancestor_id AS id,
               SUM(estimated_hours) AS total_work,
               SUM(remaining_hours) AS total_remaining_work
        FROM work_package_hierarchies wp_tree
          LEFT JOIN temp_wp_progress_values wp_progress ON wp_tree.descendant_id = wp_progress.id
        GROUP BY wp_tree.ancestor_id
      ) totals
      WHERE temp_wp_progress_values.id = totals.id
    SQL
  end

  def copy_progress_values_to_work_packages_and_update_journals
    updated_work_package_ids = copy_progress_values_to_work_packages
    create_journals_for_updated_work_packages(updated_work_package_ids)
  end

  def copy_progress_values_to_work_packages
    results = execute(<<~SQL)
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

  def create_journals_for_updated_work_packages(updated_work_package_ids)
    WorkPackage.where(id: updated_work_package_ids).find_each do |work_package|
      Journals::CreateService.new(work_package, system_user)
        .call(cause: { type: "system_update", feature: "progress_calculation_changed" })
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
# rubocop:enable Rails/SquishedSQLHeredocs

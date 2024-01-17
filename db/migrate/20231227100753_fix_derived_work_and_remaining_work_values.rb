class FixDerivedWorkAndRemainingWorkValues < ActiveRecord::Migration[7.0]
  def up
    execute(update_derived_values_as_sum_of_self_and_descendants_sql)
  end

  def down
    execute(update_derived_values_as_sum_of_descendants_sql)
    execute(update_leaf_derived_values_to_null_sql)
  end

  def update_derived_values_as_sum_of_self_and_descendants_sql
    <<~SQL.squish
      WITH wp_derived AS (
        SELECT
          wph.ancestor_id AS id,
          sum(wp.estimated_hours) AS estimated_hours_sum,
          sum(wp.remaining_hours) AS remaining_hours_sum
        FROM work_package_hierarchies wph
          LEFT JOIN work_packages wp ON wph.descendant_id = wp.id
        GROUP BY wph.ancestor_id
      )
      UPDATE
        work_packages
      SET
        derived_estimated_hours = wp_derived.estimated_hours_sum,
        derived_remaining_hours = wp_derived.remaining_hours_sum
      FROM
        wp_derived
      WHERE work_packages.id = wp_derived.id
    SQL
  end

  def update_derived_values_as_sum_of_descendants_sql
    <<~SQL.squish
      WITH wp_derived AS (
        SELECT
          wph.ancestor_id AS id,
          sum(wp.estimated_hours) AS estimated_hours_sum,
          sum(wp.remaining_hours) AS remaining_hours_sum
        FROM work_package_hierarchies wph
          LEFT JOIN work_packages wp ON wph.descendant_id = wp.id
        WHERE wph.ancestor_id != wph.descendant_id
        GROUP BY wph.ancestor_id
      )
      UPDATE
        work_packages
      SET
        derived_estimated_hours = wp_derived.estimated_hours_sum,
        derived_remaining_hours = wp_derived.remaining_hours_sum
      FROM
        wp_derived
      WHERE work_packages.id = wp_derived.id
    SQL
  end

  def update_leaf_derived_values_to_null_sql
    <<~SQL.squish
      UPDATE
        work_packages
      SET
        derived_estimated_hours = NULL,
        derived_remaining_hours = NULL
      WHERE
        id NOT IN (
          SELECT ancestor_id
          FROM work_package_hierarchies
          WHERE generations > 0
        )
    SQL
  end
end

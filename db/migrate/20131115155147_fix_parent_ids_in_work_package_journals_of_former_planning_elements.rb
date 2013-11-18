class FixParentIdsInWorkPackageJournalsOfFormerPlanningElements < ActiveRecord::Migration

  def up
    if postgres?
      ActiveRecord::Base.connection.execute <<-SQL
        UPDATE work_package_journals AS o_wpj
          SET parent_id = tmp.lpea_new_id
          FROM (
            SELECT j.id, lpe.new_id, lpe.parent_id, wpj.id AS wpj_id, wpj.parent_id AS wpj_parent_id, lpea.id, lpea.new_id AS lpea_new_id FROM legacy_planning_elements AS lpe
            JOIN journals AS j ON j.journable_id = lpe.new_id AND j.journable_type = 'WorkPackage'
            JOIN work_package_journals AS wpj ON wpj.journal_id = j.id
            LEFT JOIN legacy_planning_elements AS lpea ON lpea.id = wpj.parent_id
            WHERE wpj.parent_id IS NOT NULL AND lpea.new_id IS NOT NULL
            ORDER BY j.journable_id, j.id
          ) AS tmp
        WHERE o_wpj.id = tmp.wpj_id;
      SQL
    else
      raise "Your DBMS is not supported in this migration."
    end
  end

  def down
    # nop
  end
end

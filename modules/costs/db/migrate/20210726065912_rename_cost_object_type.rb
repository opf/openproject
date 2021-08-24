class RenameCostObjectType < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      UPDATE
        journals
      SET
        version = version + max_journal.max_version
      FROM
        (SELECT
           journable_id, MAX(version) max_version
         FROM
           journals
         WHERE
           journable_type = 'CostObject'
         GROUP BY journable_id) max_journal
      WHERE
        max_journal.journable_id = journals.journable_id
      AND
        journals.journable_type = 'Budget'
    SQL

    Journal
      .where(journable_type: 'CostObject')
      .update_all(journable_type: 'Budget')
  end

  def down
    # Doesn't need to be reverted
  end
end

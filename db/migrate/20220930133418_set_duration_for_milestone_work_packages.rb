class SetDurationForMilestoneWorkPackages < ActiveRecord::Migration[7.0]
  def up
    set_duration(:work_packages)
    set_duration(:work_package_journals)
  end

  private

  def set_duration(table)
    execute <<~SQL.squish
      UPDATE
        #{table}
      SET
        duration = 1
      WHERE
        EXISTS (
          SELECT * FROM types type
          WHERE
            type.is_milestone = TRUE AND
            type.id = #{table}.type_id
        )
    SQL
  end
end

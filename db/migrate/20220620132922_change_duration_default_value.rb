class ChangeDurationDefaultValue < ActiveRecord::Migration[7.0]
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
        duration = CASE
                   WHEN start_date IS NULL OR due_date IS NULL
                   THEN NULL
                   ELSE
                     due_date - start_date + 1
                   END
    SQL
  end
end

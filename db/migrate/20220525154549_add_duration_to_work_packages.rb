class AddDurationToWorkPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :work_packages, :duration, :integer

    add_column :work_package_journals, :duration, :integer

    reversible do |dir|
      dir.up do
        set_duration(:work_packages)
        set_duration(:work_package_journals)
      end
    end
  end

  private

  def set_duration(table)
    execute <<~SQL.squish
      UPDATE
        #{table}
      SET
        duration = CASE
                   WHEN start_date IS NULL OR due_date IS NULL
                   THEN 1
                   ELSE
                     due_date - start_date + 1
                   END
    SQL
  end
end

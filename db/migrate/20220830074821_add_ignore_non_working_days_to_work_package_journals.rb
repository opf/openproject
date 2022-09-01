class AddIgnoreNonWorkingDaysToWorkPackageJournals < ActiveRecord::Migration[7.0]
  def change
    add_column :work_package_journals, :ignore_non_working_days, :boolean

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE work_package_journals SET ignore_non_working_days = TRUE
        SQL
      end
    end

    change_column_null :work_package_journals, :ignore_non_working_days, false
  end
end

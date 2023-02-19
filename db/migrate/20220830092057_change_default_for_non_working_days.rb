class ChangeDefaultForNonWorkingDays < ActiveRecord::Migration[7.0]
  def change
    change_column_default :work_packages, :ignore_non_working_days, from: true, to: false

    reversible do |dir|
      dir.up do
        execute <<~SQL.squish
          UPDATE work_packages SET ignore_non_working_days = TRUE
        SQL
      end
    end
  end
end

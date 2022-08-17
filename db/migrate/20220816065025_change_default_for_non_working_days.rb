class ChangeDefaultForNonWorkingDays < ActiveRecord::Migration[7.0]
  def change
    change_column_default :work_packages, :ignore_non_working_days, from: true, to: false
  end
end

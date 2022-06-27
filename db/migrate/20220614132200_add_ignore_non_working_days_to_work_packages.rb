class AddIgnoreNonWorkingDaysToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :ignore_non_working_days, :boolean, default: true, null: false
  end
end

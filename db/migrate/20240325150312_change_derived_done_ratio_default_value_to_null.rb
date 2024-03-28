class ChangeDerivedDoneRatioDefaultValueToNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :work_packages, :derived_done_ratio, true
    change_column_default :work_packages, :derived_done_ratio, from: 0, to: nil
    change_column_null :work_package_journals, :derived_done_ratio, true
    change_column_default :work_package_journals, :derived_done_ratio, from: 0, to: nil
  end
end

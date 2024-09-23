class ChangeDoneRatioDefaultValueToNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :work_packages, :done_ratio, true
    change_column_default :work_packages, :done_ratio, from: 0, to: nil
    change_column_null :work_package_journals, :done_ratio, true
    change_column_default :work_package_journals, :done_ratio, from: 0, to: nil
  end
end

class AddCostsColumnToWorkPackage < ActiveRecord::Migration
  def change
    add_column :work_packages, :cost_object_id, :integer
    WorkPackage.reset_column_information

    rename_column :cost_entries, :issue_id, :work_package_id
    CostEntry.reset_column_information
  end
end

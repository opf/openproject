class AddCostsColumnToWorkPackage < ActiveRecord::Migration
  def change
    add_column :work_packages, :cost_object_id, :integer

    rename_column :cost_entries, :issue_id, :work_package_id
  end
end

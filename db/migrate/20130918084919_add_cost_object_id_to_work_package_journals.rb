class AddCostObjectIdToWorkPackageJournals < ActiveRecord::Migration
  def change
    add_column :work_package_journals, :cost_object_id, :integer, null: true
  end
end

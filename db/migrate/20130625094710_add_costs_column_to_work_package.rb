class AddCostsColumnToWorkPackage < ActiveRecord::Migration
  def change
    add_column :work_packages, :cost_object_id, :integer
  end
end

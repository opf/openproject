class DropWorkPackagesPriorityNotNullConstraint < ActiveRecord::Migration
  def change
    change_column :work_packages, :priority_id, :integer, :null => true
  end
end

class AddUpdatedAtIndexToWorkPackages < ActiveRecord::Migration
  def change
    add_index :work_packages, :updated_at
  end
end

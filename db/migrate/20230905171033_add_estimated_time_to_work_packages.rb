class AddEstimatedTimeToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :estimated_time, :float, default: 1
  end
end

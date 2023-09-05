class AddLabourRateToWorkPackages < ActiveRecord::Migration[7.0]
  def change
    add_column :work_packages, :labour_rate, :float, default: 75
  end
end

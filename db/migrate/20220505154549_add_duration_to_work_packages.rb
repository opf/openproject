class AddDurationToWorkPackages < ActiveRecord::Migration[6.1]
  def change
    add_column :work_packages, :duration, :integer
  end
end

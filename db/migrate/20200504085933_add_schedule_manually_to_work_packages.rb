class AddScheduleManuallyToWorkPackages < ActiveRecord::Migration[6.0]
  def change
    add_column :work_packages, :schedule_manually, :boolean, default: false

    # We add a partial index here because 90% of the values will be false.
    # So we only index the true values. This way the index is actually useful.
    add_index :work_packages, :schedule_manually, where: :schedule_manually
  end
end

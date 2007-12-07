class AddRoleTrackerOldStatusIndexToWorkflows < ActiveRecord::Migration
  def self.up
    add_index :workflows, [:role_id, :tracker_id, :old_status_id], :name => :workflows_role_tracker_old_status
  end

  def self.down
    remove_index :workflows, :name => :workflows_role_tracker_old_status
  end
end

class AddBacklogVelocity < ActiveRecord::Migration
  def self.up
    add_column :backlogs, :velocity, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :backlogs, :velocity
  end
end

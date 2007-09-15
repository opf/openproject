class AddIssuesEstimatedHours < ActiveRecord::Migration
  def self.up
    add_column :issues, :estimated_hours, :float
  end

  def self.down
    remove_column :issues, :estimated_hours
  end
end

class AddDeliverableToIssues < ActiveRecord::Migration
  def self.up
    add_column :issues, :deliverable_id, :integer, :null => true
  end

  def self.down
    remove_column :issues, :deliverable_id
  end
end
class AllowNullPosition < ActiveRecord::Migration
  def self.up
    # removes the 'not null' constraint on position fields
    change_column :issue_statuses, :position, :integer, :default => 1, :null => true
    change_column :roles, :position, :integer, :default => 1, :null => true
    change_column :trackers, :position, :integer, :default => 1, :null => true
    change_column :boards, :position, :integer, :default => 1, :null => true
    change_column :enumerations, :position, :integer, :default => 1, :null => true
  end

  def self.down
    # nothing to do
  end
end

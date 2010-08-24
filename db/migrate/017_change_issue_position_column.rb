class ChangeIssuePositionColumn < ActiveRecord::Migration
  def self.up
    change_column :issues, :position, :integer, :null => true, :default => nil
  end

  def self.down
    change_column :issues, :position, :integer, :null => false
  end
end

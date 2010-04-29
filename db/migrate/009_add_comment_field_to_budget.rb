class AddCommentFieldToBudget < ActiveRecord::Migration
  def self.up
    add_column :deliverable_costs, :comments, :string,  :limit => 255, :null => false, :default => ""
    add_column :deliverable_hours, :comments, :string,  :limit => 255, :null => false, :default => ""
  end
  
  def self.down
    remove_column :deliverable_costs, :comments
    remove_column :deliverable_hours, :comments
  end
end
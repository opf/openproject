class RemoveBudgetFromDeliverable < ActiveRecord::Migration
  def self.up
    remove_column :deliverables, :budget
  end
  
  def self.down
    add_column :deliverables, :budget, :decimal, :precision => 15, :scale => 2, :null => false
  end
end
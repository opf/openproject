class RemoveBudgetFromDeliverable < ActiveRecord::Migration
  def self.up
    remove_column :deliverables, :budget
  end
  
  def self.down
    t.column :budget,                   :decimal, :precision => 15, :scale => 2, :null => false
  end
end
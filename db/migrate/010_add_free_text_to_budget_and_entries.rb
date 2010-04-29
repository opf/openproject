class AddFreeTextToBudgetAndEntries < ActiveRecord::Migration
  def self.up
    add_column :deliverable_costs, :budget, :decimal, :precision => 15, :scale => 2, :null => true
    add_column :deliverable_hours, :budget, :decimal, :precision => 15, :scale => 2, :null => true

    add_column :cost_entries, :overridden_costs, :decimal, :precision => 15, :scale => 2, :null => true
  end
  
  def self.down
    remove_column :deliverable_costs, :budget
    remove_column :deliverable_hours, :budget
    
    remove_column :cost_entries, :overridden_costs
  end
end
class DeleteCostFromCostEntries < ActiveRecord::Migration
  def self.up
    remove_column :cost_entries, :cost
  end
  
  def self.down
    add_column :cost_entries, :cost, :decimal, :precission => 15, :scale => 2, :null => false
  end
end

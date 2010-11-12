class AddCostQueryVariables < ActiveRecord::Migration
  def self.up
    add_column :cost_queries, :display_cost_entries, :boolean, :default => true
    add_column :cost_queries, :display_time_entries, :boolean, :default => true
    
  end
  
  def self.down
    remove_column :cost_queries, :display_cost_entries
    remove_column :cost_queries, :display_time_entries
  end
end
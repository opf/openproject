class AdjustCostQueryLayoutSomeMore < ActiveRecord::Migration
  def self.up
    remove_column :cost_queries, :display_cost_entries
    remove_column :cost_queries, :display_time_entries
  end

  def self.down
    add_column :cost_queries, :display_cost_entries, :boolean, :default => true
    add_column :cost_queries, :display_time_entries, :boolean, :default => true
  end
end

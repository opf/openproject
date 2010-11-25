class AdjustCostQueryLayout < ActiveRecord::Migration
  def self.up
    remove_column :cost_queries, :filters
    remove_column :cost_queries, :group_by
    remove_column :cost_queries, :granularity

    add_column :cost_queries, :yamlized, :string, :null => false
  end

  def self.down
    add_column :cost_queries, :filters, :text
    add_column :cost_queries, :group_bys, :text
    add_column :cost_queries, :granularity, :string

    remove_column :cost_queries, :yamlized
  end
end
